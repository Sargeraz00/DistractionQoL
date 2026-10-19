-- TradeAdvisor.lua
-- Loot Trade Advisor & End-of-Run Loot Sheet for DistractionQoL
-- Detects tradeable party loot at dungeon/boss completion, filters for player's class,
-- identifies ilvl upgrades, and provides a 1-click polite whisper to request the item.
-- Designed with modern Obsidian Flat aesthetic (ElvUI / EllesmereUI compatible).

local addonName, DQ = ...

DQ.TradeAdvisor = {}

local activeDrops = {}
local popupFrame = nil
local isCollecting = false
local collectionTimer = nil

-- Slot mapping for equipped item level comparison
-- Retrieves lowest equipped item level in the relevant slot(s)
local function GetLowestEquippedIlvl(equipLoc)
    local slots = DQ.GameData and DQ.GameData:GetEquipmentSlots(equipLoc)
    if not slots or #slots == 0 then return 0 end

    local lowestIlvl = 9999
    local hasAny = false

    for _, slotID in ipairs(slots) do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local ilvl = (C_Item and C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(link)) or 0
            if ilvl < lowestIlvl then
                lowestIlvl = ilvl
                hasAny = true
            end
        else
            lowestIlvl = 0
            hasAny = true
        end
    end

    return hasAny and lowestIlvl or 0
end

-- Creates or retrieves the modern Obsidian Flat Popup Frame
local function GetOrCreatePopup()
    if popupFrame then return popupFrame end

    local L = DQ.L or {}
    local f = DQ.UI:CreateWindow("DistractionQoLLootAdvisorFrame", "|cff00e5ffDistractionQoL|r — " .. (L["LOOT_ADVISOR_TITLE"] or "Botín Comerciable del Encuentro"), 460, 220)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 100)

    -- Subtitle description
    local subDesc = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subDesc:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -32)
    subDesc:SetText(L["LOOT_ADVISOR_SUBTITLE"] or "Piezas de equipo obtenidas por tu grupo que podrías solicitar:")

    -- Container for dynamic item cards
    local cardsContainer = CreateFrame("Frame", nil, f)
    cardsContainer:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -52)
    cardsContainer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    f.cardsContainer = cardsContainer

    f.cards = {}
    popupFrame = f
    return popupFrame
end

-- Sends a polite whisper to the player who looted the item
local function RequestItem(looterName, itemLink, button)
    if not looterName or not itemLink then return end

    local L = DQ.L or {}
    local looterShort = DQ.Util and DQ.Util.ShortName and DQ.Util.ShortName(looterName) or (looterName:match("^([^-]+)") or looterName)

    local isSpanish = (GetLocale and (GetLocale() == "esES" or GetLocale() == "esMX"))
    local template = isSpanish and (L["LOOT_WHISPER_MSG"] or "¡Hola %s! Si no necesitas %s, ¿me lo podrías pasar, por favor? :)")
                               or  (L["LOOT_WHISPER_MSG"] or "Hey %s! If you don't need that %s, could I please have it? :)")

    local msg = string.format(template, looterShort, itemLink)

    local autoWhisper = DQ.Config:Get("loot", "autoWhisper") ~= false
    if autoWhisper then
        SendChatMessage(msg, "WHISPER", nil, looterName)
    else
        if ChatFrame_OpenChat then
            ChatFrame_OpenChat(string.format("/w %s %s", looterName, msg))
        end
    end

    -- Audio feedback
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)

    -- Update button state to requested
    if button then
        button:SetEnabled(false)
        if button.text then
            button.text:SetText("|cff00ff88✓ " .. (L["LOOT_BTN_REQUESTED"] or "Solicitado") .. "|r")
        end
        button:SetBackdropBorderColor(0.0, 0.8, 0.4, 0.8)
    end

    local printMsg = string.format(L["LOOT_MSG_SENT"] or "Susurro de solicitud enviado a %s por %s.", looterShort, itemLink)
    if DQ.Print then
        DQ:Print(printMsg)
    elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00e5ff[DistractionQoL]|r " .. printMsg)
    end
end

-- Renders the active loot cards into the popup frame
local function RefreshPopupUI()
    local f = GetOrCreatePopup()
    local L = DQ.L or {}

    -- Hide all existing cards
    for _, card in ipairs(f.cards) do
        card:Hide()
    end

    local cardHeight = 44
    local cardSpacing = 4
    local numItems = math.min(#activeDrops, 5)

    if numItems == 0 then
        f:SetHeight(100)
        f:Show()
        return
    end

    local totalHeight = 58 + (numItems * (cardHeight + cardSpacing)) + 8
    f:SetHeight(math.max(120, totalHeight))

    for i = 1, numItems do
        local drop = activeDrops[i]
        local card = f.cards[i]

        if not card then
            card = CreateFrame("Frame", nil, f.cardsContainer, "BackdropTemplate")
            card:SetHeight(cardHeight)
            if DQ.Theme and DQ.Theme.ApplyCardStyle then
                DQ.Theme.ApplyCardStyle(card)
            else
                card:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 1,
                    insets = { left = 1, right = 1, top = 1, bottom = 1 },
                })
                card:SetBackdropColor(0.10, 0.10, 0.14, 0.85)
                card:SetBackdropBorderColor(0.20, 0.20, 0.26, 1)
            end

            -- Item Icon
            local icon = card:CreateTexture(nil, "ARTWORK")
            icon:SetSize(32, 32)
            icon:SetPoint("LEFT", card, "LEFT", 6, 0)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            card.icon = icon

            -- Item Name & ilvl
            local nameText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 2)
            nameText:SetPoint("RIGHT", card, "RIGHT", -105, 0)
            nameText:SetJustifyH("LEFT")
            card.nameText = nameText

            -- Subtext: Looter & Status
            local subText = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            subText:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 0)
            subText:SetPoint("RIGHT", card, "RIGHT", -105, 0)
            subText:SetJustifyH("LEFT")
            card.subText = subText

            -- Request Button
            local reqBtn = CreateFrame("Button", nil, card, "BackdropTemplate")
            reqBtn:SetSize(94, 24)
            reqBtn:SetPoint("RIGHT", card, "RIGHT", -6, 0)
            reqBtn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 },
            })
            reqBtn:SetBackdropColor(0.0, 0.45, 0.55, 0.85)
            reqBtn:SetBackdropBorderColor(0.0, 0.85, 0.95, 1)

            local reqText = reqBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            reqText:SetPoint("CENTER")
            reqText:SetText(L["LOOT_BTN_REQUEST"] or "Pedir Ítem")
            reqBtn.text = reqText

            reqBtn:SetScript("OnEnter", function(self)
                if self:IsEnabled() then
                    self:SetBackdropColor(0.0, 0.60, 0.75, 1)
                    self:SetBackdropBorderColor(0.0, 1.0, 1.0, 1)
                end
            end)
            reqBtn:SetScript("OnLeave", function(self)
                if self:IsEnabled() then
                    self:SetBackdropColor(0.0, 0.45, 0.55, 0.85)
                    self:SetBackdropBorderColor(0.0, 0.85, 0.95, 1)
                end
            end)

            card.reqBtn = reqBtn

            -- Tooltip hover on card
            card:EnableMouse(true)
            card:SetScript("OnEnter", function(self)
                if self.itemLink then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(self.itemLink)
                    GameTooltip:Show()
                end
            end)
            card:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            f.cards[i] = card
        end

        card:SetPoint("TOPLEFT", f.cardsContainer, "TOPLEFT", 0, -((i - 1) * (cardHeight + cardSpacing)))
        card:SetPoint("TOPRIGHT", f.cardsContainer, "TOPRIGHT", 0, -((i - 1) * (cardHeight + cardSpacing)))
        card.itemLink = drop.itemLink

        -- Set Icon
        card.icon:SetTexture(drop.texture or "Interface\\Icons\\INV_Misc_QuestionMark")

        -- Quality color & item text
        local r, g, b = GetItemQualityColor(drop.quality or 1)
        card.nameText:SetText(string.format("%s |cffffffff(%d ilvl)|r", drop.itemLink or drop.itemName, drop.itemLevel or 0))

        -- Class color for looter name
        local looterColored = DQ.Util and DQ.Util.ClassColorName and DQ.Util.ClassColorName(drop.looterShort or drop.looter, drop.looterClass)
        if not looterColored then
            looterColored = drop.looter
            if drop.looterClass and RAID_CLASS_COLORS and RAID_CLASS_COLORS[drop.looterClass] then
                local cc = RAID_CLASS_COLORS[drop.looterClass]
                looterColored = string.format("|cff%02x%02x%02x%s|r", cc.r * 255, cc.g * 255, cc.b * 255, drop.looterShort or drop.looter)
            end
        end

        -- Status badge
        local statusStr
        if drop.isUpgrade and drop.ilvlDiff and drop.ilvlDiff > 0 then
            statusStr = string.format("|cff00ff00" .. (L["LOOT_STATUS_UPGRADE"] or "▲ +%d ilvl (¡Mejora!)") .. "|r", drop.ilvlDiff)
        elseif drop.isWearable then
            statusStr = "|cff00e5ff" .. (L["LOOT_STATUS_COMPATIBLE"] or "Compatible") .. "|r"
        else
            statusStr = "|cff888888" .. (L["LOOT_STATUS_INCOMPATIBLE"] or "No utilizable") .. "|r"
        end

        card.subText:SetText(string.format("%s %s  •  %s", L["LOOT_LOOTED_BY"] or "Loot de:", looterColored, statusStr))

        -- Request Button setup
        card.reqBtn:SetEnabled(not drop.requested)
        if drop.requested then
            card.reqBtn.text:SetText("|cff00ff88✓ " .. (L["LOOT_BTN_REQUESTED"] or "Solicitado") .. "|r")
            card.reqBtn:SetBackdropColor(0.08, 0.20, 0.12, 0.7)
            card.reqBtn:SetBackdropBorderColor(0.0, 0.8, 0.4, 0.6)
        else
            card.reqBtn.text:SetText(L["LOOT_BTN_REQUEST"] or "Pedir Ítem")
            card.reqBtn:SetBackdropColor(0.0, 0.45, 0.55, 0.85)
            card.reqBtn:SetBackdropBorderColor(0.0, 0.85, 0.95, 1)
            card.reqBtn:SetScript("OnClick", function(self)
                drop.requested = true
                RequestItem(drop.looter, drop.itemLink, self)
            end)
        end

        card:Show()
    end

    f:Show()
end

-- Processes a newly detected loot drop
local function ProcessLootDrop(looterName, itemLink, retryCount)
    if not itemLink or not looterName then return end
    retryCount = retryCount or 0

    -- Check config master toggle
    local enabled = DQ.Config and DQ.Config:Get("loot", "tradeAdvisor")
    if enabled == false then return end

    -- Avoid inspecting self loot
    if UnitIsUnit(looterName, "player") then return end

    local itemName, _, itemQuality, itemLevel, _, _, _, _, itemEquipLoc, itemTexture, _, classID, subclassID, bindType = C_Item.GetItemInfo(itemLink)
    if not itemName then
        if retryCount < 4 then
            C_Item.RequestLoadItemDataByID(itemLink)
            C_Timer.After(0.3, function()
                ProcessLootDrop(looterName, itemLink, retryCount + 1)
            end)
        end
        return
    end

    -- Filter non-equipment or poor quality
    if (classID ~= Enum.ItemClass.Weapon and classID ~= Enum.ItemClass.Armor) or (itemQuality and itemQuality < 2) then
        return
    end

    -- Check wearable eligibility & upgrade using TradeAdvisorLogic
    local _, playerClass = UnitClass("player")
    local effectiveIlvl = (C_Item and C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(itemLink)) or itemLevel or 0
    local equippedIlvl = GetLowestEquippedIlvl(itemEquipLoc)

    local eval = DQ.TradeAdvisorLogic and DQ.TradeAdvisorLogic.EvaluateDrop({
        classID = classID,
        subclassID = subclassID,
        equipLoc = itemEquipLoc,
        itemLevel = effectiveIlvl,
    }, playerClass, equippedIlvl) or { isWearable = true, isUpgrade = false, ilvlDiff = 0 }

    local isWearable = eval.isWearable
    local isUpgrade = eval.isUpgrade
    local ilvlDiff = eval.ilvlDiff

    local onlyEligible = DQ.Config:Get("loot", "onlyEligible")
    if onlyEligible and not isWearable then
        return
    end

    local onlyUpgrades = DQ.Config:Get("loot", "onlyUpgrades")
    if onlyUpgrades and not isUpgrade then
        return
    end

    -- Resolve looter class token
    local _, looterClass = nil, nil
    if UnitExists(looterName) then
        _, looterClass = UnitClass(looterName)
    end

    local looterShort = looterName:match("^([^-]+)") or looterName

    -- Avoid duplicates
    for _, existing in ipairs(activeDrops) do
        if existing.itemLink == itemLink and existing.looter == looterName then
            return
        end
    end

    table.insert(activeDrops, {
        itemLink = itemLink,
        itemName = itemName,
        itemLevel = effectiveIlvl,
        quality = itemQuality,
        texture = itemTexture,
        equipLoc = itemEquipLoc,
        looter = looterName,
        looterShort = looterShort,
        looterClass = looterClass,
        isWearable = isWearable,
        isUpgrade = isUpgrade,
        ilvlDiff = ilvlDiff,
        requested = false,
    })

    RefreshPopupUI()
end

-- Starts collection window for dungeon end or boss death
function DQ.TradeAdvisor:StartCollectionWindow(durationSeconds)
    isCollecting = true
    wipe(activeDrops)

    if collectionTimer then
        collectionTimer:Cancel()
    end

    collectionTimer = C_Timer.NewTimer(durationSeconds or 90, function()
        isCollecting = false
    end)
end

-- Simulates loot drops for immediate in-game testing
function DQ.TradeAdvisor:SimulateTestLoot()
    self:StartCollectionWindow(120)

    -- Sample Midnight / High-end test items
    local testItems = {
        { looter = "Valeria-Quel'Thalas", class = "PALADIN", link = "|cffa335ee|Hitem:221021::::::::70:268::11:1:3524:::|h[Coraza de Obsidiana del Vacío]|h|r" },
        { looter = "Kaelthas-Ragnaros",   class = "MAGE",    link = "|cffa335ee|Hitem:221150::::::::70:268::11:1:3524:::|h[Sortija de Tormenta de Sombras]|h|r" },
        { looter = "Sylv-Area52",        class = "HUNTER",  link = "|cffa335ee|Hitem:221200::::::::70:268::11:1:3524:::|h[Fetiche de Resonancia Cósmica]|h|r" },
    }

    for _, t in ipairs(testItems) do
        ProcessLootDrop(t.looter, t.link)
    end
end

function DQ.TradeAdvisor:Init()
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    f:RegisterEvent("ENCOUNTER_END")
    f:RegisterEvent("CHAT_MSG_LOOT")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("GROUP_LEFT")

    f:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12)
        if event == "CHALLENGE_MODE_COMPLETED" then
            DQ.TradeAdvisor:StartCollectionWindow(120)

        elseif event == "ENCOUNTER_END" then
            -- arg5 is success flag (1 = boss killed)
            if arg5 == 1 and IsInInstance() then
                DQ.TradeAdvisor:StartCollectionWindow(90)
            end

        elseif event == "CHAT_MSG_LOOT" then
            if not isCollecting then return end
            if issecretvalue and (issecretvalue(arg1) or (arg2 and issecretvalue(arg2))) then return end

            local message = arg1
            local sender = arg2

            -- Extract itemLink from message
            local itemLink = message and message:match("(|c%x+|Hitem:[^|]+|h%[[^%]]+%]h|r)")
            if itemLink then
                local looter = sender
                if not looter or looter == "" then
                    looter = message:match("^([^%s]+)")
                end
                if looter then
                    ProcessLootDrop(looter, itemLink)
                end
            end

        elseif event == "PLAYER_REGEN_DISABLED" then
            -- Auto-hide in combat to avoid obstruction and taint
            if popupFrame and popupFrame:IsShown() then
                popupFrame:Hide()
            end

        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Safely restore popup after combat if drops are pending
            if isCollecting and #activeDrops > 0 and popupFrame and not popupFrame:IsShown() then
                RefreshPopupUI()
            end

        elseif event == "GROUP_LEFT" then
            isCollecting = false
            wipe(activeDrops)
            if popupFrame and popupFrame:IsShown() then
                popupFrame:Hide()
            end
        end
    end)
end
