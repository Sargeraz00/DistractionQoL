-- ConsumablesBar.lua
-- Sleek, interactive HUD action bar for Midnight consumables with SecureActionButtonTemplate
-- Allows one-click consumption directly from bags and mouse wheel cycling between carried consumables
-- Fully compliant with Blizzard's 12.x Midnight combat lockdown and taint policies

local addonName, DQ = ...

DQ.ConsumablesBar = {}

local CATEGORIES = { "FLASK", "FOOD", "RUNE", "WEAPON" }
local BTN_SIZE = 50
local BTN_SPACING = 10
local PADDING = 12
local HEADER_HEIGHT = 28
local LABEL_HEIGHT = 16

local function GetCategoryTitle(cat)
    local L = DQ.L or {}
    if cat == "FLASK" then return L["CONSUMABLES_CAT_FLASK"] or "FLASK" end
    if cat == "FOOD" then return L["CONSUMABLES_CAT_FOOD"] or "FOOD" end
    if cat == "RUNE" then return L["CONSUMABLES_CAT_RUNE"] or "RUNE" end
    if cat == "WEAPON" then return L["CONSUMABLES_CAT_WEAPON"] or "WEAPON" end
    return cat
end

local barFrame = nil
local buttons = {}

-- Saves frame position to SavedVariables
local function SavePosition(frame)
    if not frame then return end
    local point, _, relPoint, x, y = frame:GetPoint()
    DistractionQoLDB = DistractionQoLDB or {}
    DistractionQoLDB.consumablesBarPos = {
        point = point,
        relPoint = relPoint,
        x = math.floor(x + 0.5),
        y = math.floor(y + 0.5)
    }
end

-- Restores frame position from SavedVariables
local function RestorePosition(frame)
    frame:ClearAllPoints()
    local pos = DistractionQoLDB and DistractionQoLDB.consumablesBarPos
    if pos and pos.point and pos.x and pos.y then
        frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x, pos.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
    end
end

-- Updates the visuals, attributes, and badges for an individual button
function DQ.ConsumablesBar:UpdateButtonVisuals(btn)
    if not btn then return end
    local cat = btn.category
    local items = btn.items or {}
    local count = #items
    local selected = (count > 0) and items[btn.currentIndex or 1] or nil

    if selected then
        local iconTex = selected.icon
        if not iconTex or iconTex == 0 or iconTex == 134400 then
            if C_Item and C_Item.GetItemIconByID then
                iconTex = C_Item.GetItemIconByID(selected.itemID)
            end
            if not iconTex or iconTex == 0 then
                iconTex = DQ.ConsumablesLogic.GetCategoryFallbackIcon(cat)
            end
        end
        btn.icon:SetTexture(iconTex)
        btn.icon:SetDesaturated(false)
        btn.icon:SetVertexColor(1, 1, 1, 1)
        btn.countText:SetText(tostring(selected.count))
        btn.countText:SetTextColor(1, 1, 1, 1)

        -- Scroll badge when multiple choices exist
        if count > 1 then
            btn.scrollBadge:SetText(string.format("%d/%d", btn.currentIndex, count))
            btn.scrollBadge:Show()
        else
            btn.scrollBadge:Hide()
        end

        -- Secure macro action attribute (only outside of combat)
        if not InCombatLockdown() then
            local macroText = DQ.ConsumablesLogic.BuildMacroText(cat, selected.itemID)
            btn:SetAttribute("type", "macro")
            btn:SetAttribute("macrotext", macroText)
        end
    else
        -- Empty state: no items in bags for this category
        local fallback = DQ.ConsumablesLogic.GetCategoryFallbackIcon(cat)
        btn.icon:SetTexture(fallback)
        btn.icon:SetDesaturated(true)
        btn.icon:SetVertexColor(0.60, 0.60, 0.60, 0.85)
        btn.countText:SetText("0")
        btn.countText:SetTextColor(1, 0.27, 0.27, 1)
        btn.scrollBadge:Hide()

        if not InCombatLockdown() then
            btn:SetAttribute("type", nil)
            btn:SetAttribute("macrotext", nil)
        end
    end
end

-- Updates active buff checkmark indicators on buttons
function DQ.ConsumablesBar:UpdateAuraIndicators()
    local _, missingKeys = DQ.Detection and DQ.Detection.CheckPlayerConsumables and DQ.Detection:CheckPlayerConsumables()
    missingKeys = missingKeys or {}

    for _, cat in ipairs(CATEGORIES) do
        local btn = buttons[cat]
        if btn then
            local isBuffMissing = missingKeys[cat]
            if isBuffMissing then
                btn.buffCheck:Hide()
                btn:SetBackdropBorderColor(0.24, 0.25, 0.32, 1.0)
                if btn.bottomLabel then
                    btn.bottomLabel:SetTextColor(0.70, 0.70, 0.75, 1.0)
                end
            else
                -- Buff is currently active on player!
                btn.buffCheck:Show()
                btn:SetBackdropBorderColor(0.00, 1.00, 0.53, 0.95)
                if btn.bottomLabel then
                    btn.bottomLabel:SetTextColor(0.00, 1.00, 0.53, 1.0)
                end
            end
        end
    end
end

-- Tooltip display on hover
local function OnButtonEnter(self)
    if not self then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    local L = DQ.L or {}
    local items = self.items or {}
    local selected = (items and #items > 0) and items[self.currentIndex or 1] or nil

    if selected and selected.itemID then
        GameTooltip:SetItemByID(selected.itemID)
        if #items > 1 then
            GameTooltip:AddLine(" ")
            local cycleFmt = L["CONSUMABLES_WHEEL_CYCLE"] or "|cff00e5ff[Mouse Wheel]|r Scroll to cycle (%d/%d)"
            GameTooltip:AddLine(string.format(cycleFmt, self.currentIndex, #items), 1, 1, 1)
            local distinctFmt = L["CONSUMABLES_DISTINCT_COUNT"] or "|cff888888You have %d distinct consumables in bags.|r"
            GameTooltip:AddLine(string.format(distinctFmt, #items), 0.8, 0.8, 0.8)
        end
        if self.category == "WEAPON" then
            GameTooltip:AddLine(L["CONSUMABLES_WEAPON_CLICK_HINT"] or "|cffffcc00Left-Click:|r Main Hand | |cffffcc00Right-Click:|r Off-Hand", 0.9, 0.9, 0.9)
        end
    else
        local title = GetCategoryTitle(self.category)
        local noStockFmt = L["CONSUMABLES_NO_STOCK"] or "|cffff4444[Out of Stock]|r %s"
        GameTooltip:AddLine(string.format(noStockFmt, title), 1, 0.2, 0.2)
        GameTooltip:AddLine(L["CONSUMABLES_NO_STOCK_DESC"] or "You have none of this Midnight consumable in your bags.", 0.8, 0.8, 0.8, true)
    end
    GameTooltip:Show()
end

-- Mouse wheel scrolling handler: rotates through carried items in real time
local function OnButtonMouseWheel(self, delta)
    if InCombatLockdown() then return end
    local items = self.items or {}
    if #items <= 1 then return end

    self.currentIndex = DQ.ConsumablesLogic.CycleIndex(self.currentIndex, #items, delta)
    DQ.ConsumablesBar:UpdateButtonVisuals(self)

    if PlaySound then
        pcall(PlaySound, SOUNDKIT.U_CHAT_SCROLL_BUTTON or 1115, "Master")
    end

    if GameTooltip:IsOwned(self) then
        OnButtonEnter(self)
    end
end

-- Creates an individual secure category button with Material Design styling
local function CreateCategoryButton(parent, cat, index)
    local btnName = "DistractionQoLConsumablesBtn_" .. cat
    local btn = CreateFrame("Button", btnName, parent, "SecureActionButtonTemplate, BackdropTemplate")
    btn:SetSize(BTN_SIZE, BTN_SIZE)
    local xOffset = PADDING + (index - 1) * (BTN_SIZE + BTN_SPACING)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -(HEADER_HEIGHT + 6))
    btn.category = cat
    btn.currentIndex = 1

    -- Material Card Surface Backdrop
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    btn:SetBackdropColor(0.10, 0.10, 0.14, 0.96)
    btn:SetBackdropBorderColor(0.24, 0.25, 0.32, 1.0)

    -- Icon Texture (placed in ARTWORK layer to avoid backdrop z-fighting)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    -- Highlight Texture
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetColorTexture(1, 1, 1, 0.20)
    hl:SetAllPoints(icon)

    -- Pushed Texture
    btn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    local pushed = btn:GetPushedTexture()
    if pushed then
        pushed:SetAllPoints(icon)
    end

    -- Stack Count Label
    local count = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3, 3)
    count:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    btn.countText = count

    -- Scroll Badge (Material Chip e.g. 1/3)
    local badge = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badge:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -3, -3)
    badge:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    badge:SetTextColor(0.0, 0.90, 1.0, 1.0)
    btn.scrollBadge = badge

    -- Active Buff Checkmark Overlay (sharp native Blizzard texture)
    local buffCheck = btn:CreateTexture(nil, "OVERLAY", nil, 7)
    buffCheck:SetSize(18, 18)
    buffCheck:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    buffCheck:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    buffCheck:Hide()
    btn.buffCheck = buffCheck

    -- Category Subtitle Label below button
    local bottomLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bottomLabel:SetPoint("TOP", btn, "BOTTOM", 0, -4)
    bottomLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    bottomLabel:SetText(GetCategoryTitle(cat))
    bottomLabel:SetTextColor(0.70, 0.70, 0.75, 1.0)
    btn.bottomLabel = bottomLabel

    -- Secure Action clicks setup
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:EnableMouseWheel(true)
    btn:SetScript("OnEnter", OnButtonEnter)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:SetScript("OnMouseWheel", OnButtonMouseWheel)

    return btn
end

-- Constructs the main floating bar frame with Material Design styling
local function CreateBarFrame()
    if barFrame then return barFrame end

    local totalWidth = PADDING * 2 + (#CATEGORIES * BTN_SIZE) + ((#CATEGORIES - 1) * BTN_SPACING)
    local totalHeight = HEADER_HEIGHT + 6 + BTN_SIZE + 4 + LABEL_HEIGHT + PADDING

    local f = CreateFrame("Frame", "DistractionQoLConsumablesBar", UIParent, "BackdropTemplate")
    f:SetSize(totalWidth, totalHeight)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
    end)

    -- Material Elevated Surface Backdrop
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    f:SetBackdropColor(0.08, 0.08, 0.11, 0.97)
    f:SetBackdropBorderColor(0.20, 0.21, 0.27, 1.0)

    -- Top Accent strip (Electric Cyan)
    local topBar = f:CreateTexture(nil, "ARTWORK")
    topBar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    topBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    topBar:SetHeight(2)
    topBar:SetColorTexture(0.0, 0.85, 0.95, 1.0)

    -- Header Title
    local L = DQ.L or {}
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", PADDING, -7)
    title:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    title:SetText("|cff00e5ff" .. (L["CONSUMABLES_BAR_TITLE"] or "CONSUMABLES") .. "|r")
    f.titleText = title

    -- Compatibility / Conflict Settings Gear Button
    local btnCompat = CreateFrame("Button", nil, f)
    btnCompat:SetSize(18, 18)
    btnCompat:SetPoint("LEFT", title, "RIGHT", 8, 0)
    local gearIcon = btnCompat:CreateTexture(nil, "ARTWORK")
    gearIcon:SetSize(14, 14)
    gearIcon:SetPoint("CENTER")
    gearIcon:SetTexture("Interface\\WorldMap\\Gear_64")
    gearIcon:SetVertexColor(0.70, 0.70, 0.75, 1)
    btnCompat.icon = gearIcon

    btnCompat:SetScript("OnEnter", function(self)
        self.icon:SetVertexColor(0.0, 0.90, 1.0, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local locL = DQ.L or {}
        local choice = (DQ.ConflictResolver and DQ.ConflictResolver:GetChoice("consumables")) or "DistractionQoL"
        GameTooltip:AddLine("|cff00e5ff" .. (locL["CONSUMABLES_GEAR_TITLE"] or "Consumables Management") .. "|r", 1, 1, 1)
        local managedFmt = locL["CONSUMABLES_GEAR_MANAGED_BY"] or "Currently managed by: |cff00ff88%s|r"
        GameTooltip:AddLine(string.format(managedFmt, choice), 0.9, 0.9, 0.9)
        GameTooltip:AddLine(locL["CONSUMABLES_GEAR_HINT"] or "|cffffcc00Click:|r Open conflict manager (DistractionQoL vs EllesmereUI).", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    btnCompat:SetScript("OnLeave", function(self)
        self.icon:SetVertexColor(0.70, 0.70, 0.75, 1)
        GameTooltip:Hide()
    end)
    btnCompat:SetScript("OnClick", function()
        DQ.ConsumablesBar:OpenManager(true)
    end)

    -- Close Button (X)
    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(18, 18)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PADDING + 4, -5)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText:SetPoint("CENTER", 0, 0)
    closeText:SetText("|cff888888X|r")
    closeBtn:SetScript("OnEnter", function() closeText:SetText("|cffff4444X|r") end)
    closeBtn:SetScript("OnLeave", function() closeText:SetText("|cff888888X|r") end)
    closeBtn:SetScript("OnClick", function()
        DQ.ConsumablesBar:HideBar()
    end)

    -- Create category buttons
    for i, cat in ipairs(CATEGORIES) do
        buttons[cat] = CreateCategoryButton(f, cat, i)
    end

    RestorePosition(f)
    f:Hide()

    -- Combat & Event Shielding (PLAYER_REGEN_ENABLED is permanent; UNIT_AURA & BAG_UPDATE are dynamic)
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_REGEN_ENABLED" then
            if self._pendingHide then
                self._pendingHide = nil
                DQ.ConsumablesBar:HideBar()
            elseif self._pendingUpdate then
                self._pendingUpdate = nil
                DQ.ConsumablesBar:Refresh()
            end
        elseif event == "BAG_UPDATE_DELAYED" then
            if self:IsShown() and not InCombatLockdown() then
                DQ.ConsumablesBar:Refresh()
            end
        elseif event == "UNIT_AURA" and unit == "player" then
            if self:IsShown() and not InCombatLockdown() then
                -- Update active buff indicators
                DQ.ConsumablesBar:UpdateAuraIndicators()

                -- Only auto-dismiss if opened automatically by ready check, NOT if manually pinned
                if not self._isManualPinned then
                    local missing = DQ.Detection and DQ.Detection.CheckPlayerConsumables and DQ.Detection:CheckPlayerConsumables()
                    if missing and #missing == 0 then
                        DQ.ConsumablesBar:HideBar()
                    end
                end
            end
        end
    end)

    barFrame = f
    return f
end

-- Refreshes the carried items and button states across all categories
function DQ.ConsumablesBar:Refresh(missingKeys)
    if InCombatLockdown() then
        if barFrame then barFrame._pendingUpdate = true end
        return
    end

    local frame = CreateBarFrame()
    local flatBag = DQ.ConsumablesLogic.ScanPlayerBags()
    local grouped = DQ.ConsumablesLogic.GroupBagItems(flatBag)

    for _, cat in ipairs(CATEGORIES) do
        local btn = buttons[cat]
        if btn then
            local prevItem = (btn.items and #btn.items > 0) and btn.items[btn.currentIndex or 1]
            btn.items = grouped[cat] or {}
            btn.currentIndex = 1

            -- Preserve previous item selection if still present in bags
            if prevItem and #btn.items > 1 then
                for idx, it in ipairs(btn.items) do
                    if it.itemID == prevItem.itemID then
                        btn.currentIndex = idx
                        break
                    end
                end
            end

            DQ.ConsumablesBar:UpdateButtonVisuals(btn)
        end
    end

    DQ.ConsumablesBar:UpdateAuraIndicators()
end

-- Displays the consumables bar with current status
function DQ.ConsumablesBar:ShowBar(missingKeys, isManual)
    if InCombatLockdown() then
        return
    end
    local frame = CreateBarFrame()
    frame._isManualPinned = isManual and true or false

    if frame.RegisterUnitEvent then
        frame:RegisterUnitEvent("UNIT_AURA", "player")
    else
        frame:RegisterEvent("UNIT_AURA")
    end
    frame:RegisterEvent("BAG_UPDATE_DELAYED")

    DQ.ConsumablesBar:Refresh(missingKeys)
    frame:Show()
end

-- Hides the consumables bar safely
function DQ.ConsumablesBar:HideBar()
    if not barFrame then return end
    if InCombatLockdown() then
        barFrame._pendingHide = true
        return
    end
    barFrame._isManualPinned = false
    barFrame:UnregisterEvent("UNIT_AURA")
    barFrame:UnregisterEvent("BAG_UPDATE_DELAYED")
    barFrame:Hide()
end

-- Toggle bar visibility on slash command
function DQ.ConsumablesBar:Toggle()
    if barFrame and barFrame:IsShown() then
        DQ.ConsumablesBar:HideBar()
    else
        DQ.ConsumablesBar:ShowBar(nil, true)
    end
end

-- Full interactive manager entry point: opens conflict resolver if unconfigured, plus pinned consumables bar
function DQ.ConsumablesBar:OpenManager(forcePrompt)
    local ext = DQ.ConflictResolver and DQ.ConflictResolver:DetectConflict("consumables")
    local choice = DQ.ConflictResolver and DQ.ConflictResolver:GetChoice("consumables")

    -- 1. Check who controls the feature: if conflict detected and (unconfigured OR forcePrompt requested)
    if ext and (not choice or forcePrompt) then
        DQ.ConflictResolver:QueuePrompt("consumables", ext, function(selectedChoice, remember)
            DQ.ConflictResolver:SetChoice("consumables", selectedChoice, remember)
        end)
    else
        local activeController = choice or "DistractionQoL"
        local L = DQ.L or {}
        local prefix = "|cff00e5ff[" .. (L["CONSUMABLES_BAR_TITLE"] or "Consumables") .. "]|r "
        local infoFmt = L["CONSUMABLES_MSG_CTRL_STATUS"] or "Active controller: |cff00ff88%s|r. Type /consumables choose or click [⚙] to switch."
        local infoMsg = string.format(infoFmt, activeController)
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage(prefix .. infoMsg)
        elseif print then
            print(prefix .. infoMsg)
        end
    end

    -- 2. Open the pinned interactive Consumables Bar
    DQ.ConsumablesBar:ShowBar(nil, true)

    if PlaySound then
        pcall(PlaySound, SOUNDKIT.IG_MAINMENU_OPEN or 850, "Master")
    end
end

-- Dedicated Top-Level Slash Commands: /consumables, /consumible, /frascos
SLASH_DISTRACTIONQOL_CONSUMABLES1 = "/consumables"
SLASH_DISTRACTIONQOL_CONSUMABLES2 = "/consumible"
SLASH_DISTRACTIONQOL_CONSUMABLES3 = "/frascos"
SlashCmdList["DISTRACTIONQOL_CONSUMABLES"] = function(msg)
    local sub = (msg or ""):lower():match("^%s*(%S*)")
    local forcePrompt = (sub == "choose" or sub == "setup" or sub == "prompt" or sub == "conflict" or sub == "conflicts" or sub == "cambiar")
    DQ.ConsumablesBar:OpenManager(forcePrompt)
end
