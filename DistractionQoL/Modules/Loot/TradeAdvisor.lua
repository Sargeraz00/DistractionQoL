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
            button.text:SetText("|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14:0:0|t |cff00ff88" .. (L["LOOT_BTN_REQUESTED"] or "Solicitado") .. "|r")
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
                if self.simTooltip then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:ClearLines()
                    for _, line in ipairs(self.simTooltip) do
                        if line.right then
                            local lr, lg, lb = line.lr or 1, line.lg or 1, line.lb or 1
                            local rr, rg, rb = line.rr or 1, line.rg or 1, line.rb or 1
                            GameTooltip:AddDoubleLine(line.left, line.right, lr, lg, lb, rr, rg, rb)
                        else
                            local r, g, b = line.r or 1, line.g or 1, line.b or 1
                            GameTooltip:AddLine(line.left or line.text, r, g, b, line.wrap or false)
                        end
                    end
                    GameTooltip:Show()
                elseif self.itemLink then
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
        card.simTooltip = drop.simTooltip

        -- Set Icon
        card.icon:SetTexture(drop.texture or "Interface\\Icons\\INV_Misc_QuestionMark")

        -- Item text with ilvl
        local itemDisplayName = drop.itemLink
        if not itemDisplayName then
            local qc = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[drop.quality or 1]
            local r = qc and qc.r or 1
            local g = qc and qc.g or 1
            local b = qc and qc.b or 1
            itemDisplayName = string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, drop.itemName or "Objeto")
        end
        card.nameText:SetText(string.format("%s |cffffffff(%d ilvl)|r", itemDisplayName, drop.itemLevel or 0))

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
            statusStr = string.format("|cff00ff00" .. (L["LOOT_STATUS_UPGRADE"] or "+%d ilvl (¡Mejora!)") .. "|r", drop.ilvlDiff)
        elseif drop.isWearable then
            statusStr = "|cff00e5ff" .. (L["LOOT_STATUS_COMPATIBLE"] or "Compatible") .. "|r"
        else
            statusStr = "|cff888888" .. (L["LOOT_STATUS_INCOMPATIBLE"] or "No utilizable") .. "|r"
        end

        card.subText:SetText(string.format("%s %s  •  %s", L["LOOT_LOOTED_BY"] or "Loot de:", looterColored, statusStr))

        -- Request Button setup
        card.reqBtn:SetEnabled(not drop.requested)
        if drop.requested then
            card.reqBtn.text:SetText("|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14:0:0|t |cff00ff88" .. (L["LOOT_BTN_REQUESTED"] or "Solicitado") .. "|r")
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

    -- Instant DBC attributes (synchronous, 0ms, zero network lag)
    local instItemID, instItemType, instItemSubType, instEquipLoc, instTexture, instClassID, instSubclassID
    if C_Item and C_Item.GetItemInfoInstant then
        instItemID, instItemType, instItemSubType, instEquipLoc, instTexture, instClassID, instSubclassID = C_Item.GetItemInfoInstant(itemLink)
    end

    local itemName, _, itemQuality, itemLevel, _, _, _, _, itemEquipLoc, itemTexture, _, classID, subclassID = C_Item.GetItemInfo(itemLink)

    local itemID = instItemID or tonumber(itemLink:match("item:(%d+)"))
    local bracketName = itemLink:match("%[([^%]]+)%]")
    local effectiveIlvl = (C_Item and C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(itemLink)) or itemLevel or 0

    itemName = itemName or bracketName or (instItemType and (instItemType .. " " .. (instItemSubType or ""))) or "Objeto de Mazmorra"
    classID = classID or instClassID or (Enum.ItemClass and Enum.ItemClass.Armor or 4)
    subclassID = subclassID or instSubclassID or 0
    itemEquipLoc = itemEquipLoc or instEquipLoc or "INVTYPE_CHEST"
    itemTexture = itemTexture or instTexture or (itemID and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID)) or "Interface\\Icons\\INV_Misc_QuestionMark"
    effectiveIlvl = (effectiveIlvl > 0 and effectiveIlvl) or itemLevel or 0

    -- If quality is missing, infer from hyperlink color code
    if not itemQuality then
        local hex = itemLink:match("|cff(%x%x%x%x%x%x)")
        if hex then
            hex = hex:lower()
            if hex == "a335ee" then itemQuality = 4
            elseif hex == "0070dd" then itemQuality = 3
            elseif hex == "1eff00" then itemQuality = 2
            elseif hex == "ff8000" then itemQuality = 5
            else itemQuality = 1 end
        else
            itemQuality = 4
        end
    end

    -- Asynchronously request item data cache if full name was missing
    if not itemName and itemID and retryCount < 3 and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
        C_Timer.After(0.3, function()
            ProcessLootDrop(looterName, itemLink, retryCount + 1)
        end)
        return
    end

    -- Filter non-equipment or poor quality
    local isWeapon = (classID == (Enum.ItemClass and Enum.ItemClass.Weapon or 2))
    local isArmor  = (classID == (Enum.ItemClass and Enum.ItemClass.Armor or 4))
    if (not isWeapon and not isArmor) or (itemQuality and itemQuality < 2) then
        return
    end

    -- Check wearable eligibility & upgrade using TradeAdvisorLogic
    local _, playerClass = UnitClass("player")
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

    collectionTimer = C_Timer.NewTimer(durationSeconds or 300, function()
        isCollecting = false
    end)
end

-- Generates realistic Midnight Season 2 simulated loot drops (Ula'tek Mythic & Season 2 Heroic)
local function GetSimulatedDrops()
    local L = DQ.L or {}
    local _, playerClass = UnitClass("player")
    playerClass = playerClass or "WARRIOR"

    local myArmorSubclass = (DQ.GameData and DQ.GameData:GetArmorSubclass(playerClass)) or 4
    local armorName = (myArmorSubclass == 4 and (L["SIM_ARMOR_PLATE"] or "Placas"))
                   or (myArmorSubclass == 3 and (L["SIM_ARMOR_MAIL"] or "Malla"))
                   or (myArmorSubclass == 2 and (L["SIM_ARMOR_LEATHER"] or "Cuero"))
                   or (L["SIM_ARMOR_CLOTH"] or "Tela")

    local chestItemId = (myArmorSubclass == 4 and 268222)
                     or (myArmorSubclass == 3 and 271876)
                     or (myArmorSubclass == 2 and 271875)
                     or 271874

    local chestName = (myArmorSubclass == 4 and (L["SIM_CHEST_PLATE"] or "Coraza de espíritu temerario"))
                   or (myArmorSubclass == 3 and (L["SIM_CHEST_MAIL"] or "Loriga de colminferno despierto"))
                   or (myArmorSubclass == 2 and (L["SIM_CHEST_LEATHER"] or "Mirada del vigía enroscado"))
                   or (L["SIM_CHEST_CLOTH"] or "Capucha horripilante guardavenenos")

    local primaryStatName = (myArmorSubclass == 4 and (L["SIM_STAT_STRENGTH"] or "+%s Fuerza"))
                         or (myArmorSubclass == 1 and (L["SIM_STAT_INTELLECT"] or "+%s Intelecto"))
                         or (L["SIM_STAT_AGILITY"] or "+%s Agilidad")

    -- Official Blizzard FileDataIDs from Battle.net Game Data API
    local chestIcon = (myArmorSubclass == 4 and 7515795)
                   or (myArmorSubclass == 3 and 7789856)
                   or (myArmorSubclass == 2 and 7579164)
                   or 7520904

    local ringIcon = 7866597
    local trinketIcon = 7956750

    -- Dynamically check player's equipped ilvl
    local eqChest = GetLowestEquippedIlvl("INVTYPE_CHEST")
    local eqFinger = GetLowestEquippedIlvl("INVTYPE_FINGER")
    local eqTrinket = GetLowestEquippedIlvl("INVTYPE_TRINKET")

    -- Realistic fallback: high-end Midnight player baseline is ~335
    local refChest = (eqChest and eqChest >= 300) and eqChest or 335
    local refFinger = (eqFinger and eqFinger >= 300) and eqFinger or 335
    local refTrinket = (eqTrinket and eqTrinket >= 300) and eqTrinket or 335

    -- Item 1: Chest (Ula'tek Mythic full 6/6 -> 344 ilvl)
    local chestIlvl = 344
    local chestDiff = math.max(1, chestIlvl - refChest)
    local chestLink = string.format("|cffa335ee|Hitem:%d::::::::80:268::11:1:3524:::|h[%s]|h|r", chestItemId, chestName)

    -- Item 2: Ring (Ula'tek Mythic full 6/6 -> 344 ilvl)
    local ringName = L["SIM_RING_NAME"] or "Sortija de alquimista vil"
    local ringIlvl = 344
    local ringDiff = math.max(1, ringIlvl - refFinger)
    local ringLink = string.format("|cffa335ee|Hitem:268249::::::::80:268::11:1:3524:::|h[%s]|h|r", ringName)

    -- Item 3: Trinket (Season 2 Heroic 4/6 -> 328 ilvl, below player's 335)
    local trinketName = L["SIM_TRINKET_NAME"] or "Corazón voraz de Ula'tek"
    local trinketIlvl = 328
    local trinketDiff = math.max(0, trinketIlvl - refTrinket)
    local isTrinketUpgrade = (trinketDiff > 0)
    local trinketLink = string.format("|cffa335ee|Hitem:270175::::::::80:268::11:1:3524:::|h[%s]|h|r", trinketName)

    return {
        {
            looter = "Valeria-Quel'Thalas",
            looterShort = "Valeria",
            looterClass = "PALADIN",
            itemName = chestName,
            itemLink = chestLink,
            itemLevel = chestIlvl,
            quality = 4,
            texture = chestIcon,
            equipLoc = "INVTYPE_CHEST",
            isWearable = true,
            isUpgrade = true,
            ilvlDiff = chestDiff,
            requested = false,
            simTooltip = {
                { left = chestName, r = 0.64, g = 0.21, b = 0.93 },
                { left = string.format(L["SIM_ILVL_LABEL"] or "Nivel de objeto %d", chestIlvl), right = L["SIM_TRACK_MYTHIC"] or "Mítico 6/6", lr = 1, lg = 1, lb = 1, rr = 0.0, rg = 1.0, rb = 0.59 },
                { left = L["SIM_BIND_BOP"] or "Se liga al recogerlo", r = 1, g = 1, b = 1 },
                { left = L["SIM_SLOT_CHEST"] or "Torso", right = armorName, lr = 1, lg = 1, lb = 1, rr = 1, rg = 1, rb = 1 },
                { left = string.format(primaryStatName, "3,280"), r = 1, g = 1, b = 1 },
                { left = string.format(L["SIM_STAT_STAMINA"] or "+%s Aguante", "6,560"), r = 1, g = 1, b = 1 },
                { left = string.format(L["SIM_STAT_CRIT"] or "+%s Golpe crítico", "685"), r = 0.0, g = 1.0, b = 0.0 },
                { left = string.format(L["SIM_STAT_HASTE"] or "+%s Celeridad", "590"), r = 0.0, g = 1.0, b = 0.0 },
                { left = " ", r = 1, g = 1, b = 1 },
                { left = L["SIM_SOURCE_ULATEK"] or "Jefe: Ula'tek (El Abismo Venenoso - Mítico)", r = 0.0, g = 0.9, b = 1.0 },
            },
        },
        {
            looter = "Kaelthas-Ragnaros",
            looterShort = "Kaelthas",
            looterClass = "MAGE",
            itemName = ringName,
            itemLink = ringLink,
            itemLevel = ringIlvl,
            quality = 4,
            texture = ringIcon,
            equipLoc = "INVTYPE_FINGER",
            isWearable = true,
            isUpgrade = true,
            ilvlDiff = ringDiff,
            requested = false,
            simTooltip = {
                { left = ringName, r = 0.64, g = 0.21, b = 0.93 },
                { left = string.format(L["SIM_ILVL_LABEL"] or "Nivel de objeto %d", ringIlvl), right = L["SIM_TRACK_MYTHIC"] or "Mítico 6/6", lr = 1, lg = 1, lb = 1, rr = 0.0, rg = 1.0, rb = 0.59 },
                { left = L["SIM_BIND_BOP"] or "Se liga al recogerlo", r = 1, g = 1, b = 1 },
                { left = L["SIM_SLOT_FINGER"] or "Dedo", r = 1, g = 1, b = 1 },
                { left = string.format(L["SIM_STAT_STAMINA"] or "+%s Aguante", "6,560"), r = 1, g = 1, b = 1 },
                { left = string.format(L["SIM_STAT_CRIT"] or "+%s Golpe crítico", "1,120"), r = 0.0, g = 1.0, b = 0.0 },
                { left = string.format(L["SIM_STAT_MASTERY"] or "+%s Maestría", "980"), r = 0.0, g = 1.0, b = 0.0 },
                { left = " ", r = 1, g = 1, b = 1 },
                { left = L["SIM_SOURCE_ULATEK"] or "Jefe: Ula'tek (El Abismo Venenoso - Mítico)", r = 0.0, g = 0.9, b = 1.0 },
            },
        },
        {
            looter = "Sylv-Area52",
            looterShort = "Sylv",
            looterClass = "HUNTER",
            itemName = trinketName,
            itemLink = trinketLink,
            itemLevel = trinketIlvl,
            quality = 4,
            texture = trinketIcon,
            equipLoc = "INVTYPE_TRINKET",
            isWearable = true,
            isUpgrade = isTrinketUpgrade,
            ilvlDiff = trinketDiff,
            requested = false,
            simTooltip = {
                { left = trinketName, r = 0.64, g = 0.21, b = 0.93 },
                { left = string.format(L["SIM_ILVL_LABEL"] or "Nivel de objeto %d", trinketIlvl), right = L["SIM_TRACK_HEROIC"] or "Heroico 4/6", lr = 1, lg = 1, lb = 1, rr = 0.0, rg = 1.0, rb = 0.59 },
                { left = L["SIM_BIND_BOP"] or "Se liga al recogerlo", r = 1, g = 1, b = 1 },
                { left = L["SIM_SLOT_TRINKET"] or "Abalorio", r = 1, g = 1, b = 1 },
                { left = string.format(primaryStatName, "1,820"), r = 1, g = 1, b = 1 },
                { left = L["SIM_TRINKET_USE"] or "Uso: Desata un torrente de veneno abisal que inflige daño de las Sombras durante 15 s. (2 min reutilización)", r = 0.0, g = 1.0, b = 0.0, wrap = true },
                { left = " ", r = 1, g = 1, b = 1 },
                { left = L["SIM_SOURCE_DUNGEON"] or "Botín: Mazmorra de Temporada 2 (Heroico)", r = 0.0, g = 0.9, b = 1.0 },
            },
        },
    }
end

-- Simulates loot drops for immediate in-game testing
function DQ.TradeAdvisor:SimulateTestLoot()
    self:StartCollectionWindow(300)
    wipe(activeDrops)

    local simDrops = GetSimulatedDrops()
    for _, drop in ipairs(simDrops) do
        table.insert(activeDrops, drop)
    end

    RefreshPopupUI()
end

function DQ.TradeAdvisor:Init()
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    f:RegisterEvent("ENCOUNTER_END")
    f:RegisterEvent("ENCOUNTER_LOOT_RECEIVED")
    f:RegisterEvent("CHAT_MSG_LOOT")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("GROUP_LEFT")

    f:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4, arg5)
        if event == "CHALLENGE_MODE_COMPLETED" then
            DQ.TradeAdvisor:StartCollectionWindow(300)

        elseif event == "ENCOUNTER_END" then
            -- arg5 is success flag (1 = boss killed)
            if arg5 == 1 and IsInInstance() then
                DQ.TradeAdvisor:StartCollectionWindow(180)
            end

        elseif event == "ENCOUNTER_LOOT_RECEIVED" then
            if not isCollecting then return end
            -- arg3 is itemLink, arg5 is playerName
            local itemLink = arg3
            local looter = arg5
            if itemLink and looter then
                ProcessLootDrop(looter, itemLink)
            end

        elseif event == "CHAT_MSG_LOOT" then
            if not isCollecting then return end
            if issecretvalue and (issecretvalue(arg1) or (arg2 and issecretvalue(arg2))) then return end

            local message = arg1
            local sender = arg2

            -- Extract itemLink from message with resilient fallback regexes
            local itemLink = message and (
                message:match("(|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r)")
                or message:match("(|c%x+|Hitem:[^|]+|h.-|h|r)")
                or message:match("(item:[%d:-]+)")
            )
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
