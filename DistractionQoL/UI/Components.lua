-- Components.lua
-- Reusable UI primitives and widgets for DistractionQoL
-- Clean flat obsidian styling, accessible checkboxes, and persistent choice toggles

local addonName, DQ = ...

DQ.UI = DQ.UI or {}

-- Helper to dynamically resolve sound icon texture path regardless of folder name
local resolvedIconsDir = nil
function DQ.UI:GetIconPath(iconName)
    if not resolvedIconsDir then
        local base = "Interface\\AddOns\\" .. (addonName or "DistractionQoL") .. "\\Media\\Icons\\"
        local testTex = UIParent:CreateTexture()
        if testTex:SetTexture(base .. "m3_release.png") then
            resolvedIconsDir = base
        else
            resolvedIconsDir = "Interface\\AddOns\\DistractionQoL\\Media\\Icons\\"
        end
    end
    return resolvedIconsDir .. iconName
end

function DQ.UI:ResolveSoundPath(isOn)
    local icon = isOn and "m3_sound_on.png" or "m3_sound_off.png"
    return self:GetIconPath(icon)
end

function DQ.UI:GetSoundIcon(isOn, size)
    size = size or 16
    local path = self:ResolveSoundPath(isOn)
    return string.format("|T%s:%d:%d:0:0|t ", path, size, size)
end

-- Helper to create standard Obsidian Flat Dialog/Window frames
function DQ.UI:CreateWindow(frameName, titleText, width, height)
    local f = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    f:SetSize(width or 560, height or 520)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    if DQ.Theme and DQ.Theme.ApplyWindowStyle then
        DQ.Theme.ApplyWindowStyle(f)
    else
        f:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = false,
            tileSize = 0,
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        f:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
        f:SetBackdropBorderColor(0.22, 0.22, 0.26, 1)

        local bg = f:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
        bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
        bg:SetColorTexture(0.06, 0.06, 0.08, 0.98)
        f._dqSolidBg = bg
    end

    -- Header background bar
    local headerBar = f:CreateTexture(nil, "BACKGROUND", nil, -5)
    headerBar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    headerBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    headerBar:SetHeight(26)
    headerBar:SetColorTexture(0, 0, 0, 0.50)
    f.headerBar = headerBar

    -- Top Cyan Accent strip
    local topBar = f:CreateTexture(nil, "ARTWORK")
    topBar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    topBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    topBar:SetHeight(2)
    topBar:SetColorTexture(0.0, 0.85, 0.95, 1)
    f.topAccent = topBar

    -- Title
    local fontBold = (DQ.Theme and DQ.Theme.GetFont and DQ.Theme.GetFont("bold")) or "Fonts\\FRIZQT__.TTF"
    local m3 = (DQ.Theme and DQ.Theme.M3) or {}

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(fontBold, 13, "")
    title:SetShadowOffset(0, 0)
    title:SetPoint("LEFT", f, "TOPLEFT", 12, -13)
    title:SetTextColor(unpack(m3.primary or { 0.0, 0.90, 1.0, 1.0 }))
    title:SetText(titleText or "|cff00e5ffDistractionQoL|r")
    f.title = title
    f.TitleText = title

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        if not InCombatLockdown or not InCombatLockdown() then
            f:Hide()
        end
    end)

    local xText = closeBtn:CreateFontString(nil, "OVERLAY")
    xText:SetFont(fontBold, 12, "")
    xText:SetShadowOffset(0, 0)
    xText:SetPoint("CENTER", closeBtn, "CENTER", 0, 1)
    xText:SetText("|cffaaaaaaX|r")
    closeBtn.xText = xText

    closeBtn:HookScript("OnEnter", function(self)
        if not self.isSkinned and self.xText then self.xText:SetText("|cffff3333X|r") end
    end)
    closeBtn:HookScript("OnLeave", function(self)
        if not self.isSkinned and self.xText then self.xText:SetText("|cffaaaaaaX|r") end
    end)
    f.closeBtn = closeBtn
    f.CloseButton = closeBtn

    return f
end

-- Helper to create modern Material Design 3 (M3) Checkboxes
function DQ.UI:CreateCheckbox(parent, label, x, y, initialChecked, onClick, maxTextWidth)
    local cb = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetSize(18, 18)
    cb:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })

    local fontPath = (DQ.Theme and DQ.Theme.GetFont and DQ.Theme.GetFont("regular")) or "Fonts\\FRIZQT__.TTF"
    local m3 = (DQ.Theme and DQ.Theme.M3) or {}

    -- Crisp vector checkmark icon
    local check = cb:CreateTexture(nil, "ARTWORK")
    check:SetSize(14, 14)
    check:SetPoint("CENTER")
    check:SetTexture(self:GetIconPath("m3_check.png"))
    cb.checkIcon = check

    local text = cb:CreateFontString(nil, "OVERLAY")
    text:SetFont(fontPath, 12, "")
    text:SetShadowOffset(0, 0)
    text:SetPoint("LEFT", cb, "RIGHT", 8, 0)
    text:SetWordWrap(true)
    text:SetJustifyH("LEFT")
    if maxTextWidth then
        text:SetWidth(maxTextWidth)
    end
    text:SetText(label or "")
    cb.text = text

    local function UpdateVisuals(isChecked, isHover)
        local isEnabled = cb:IsEnabled()
        if not isEnabled then
            cb:SetBackdropColor(0.08, 0.10, 0.12, 0.40)
            cb:SetBackdropBorderColor(0.20, 0.22, 0.25, 0.40)
            check:Hide()
            text:SetTextColor(0.40, 0.44, 0.48, 1.0)
            return
        end

        if isChecked then
            -- M3 Active / Checked state: Electric Cyan fill with dark-teal check
            if isHover then
                cb:SetBackdropColor(0.20, 0.95, 1.00, 1.0)
                cb:SetBackdropBorderColor(0.40, 1.00, 1.00, 1.0)
            else
                cb:SetBackdropColor(unpack(m3.primary or { 0.0, 0.90, 1.0, 1.0 }))
                cb:SetBackdropBorderColor(unpack(m3.primary or { 0.0, 0.90, 1.0, 1.0 }))
            end
            check:Show()
            check:SetVertexColor(0.00, 0.10, 0.12, 1.0)
            text:SetTextColor(1, 1, 1, 1)
        else
            -- M3 Inactive / Unchecked state: Low surface with subtle outline
            if isHover then
                cb:SetBackdropColor(0.18, 0.24, 0.28, 0.95)
                cb:SetBackdropBorderColor(unpack(m3.primary or { 0.0, 0.90, 1.0, 1.0 }))
                text:SetTextColor(1, 1, 1, 1)
            else
                cb:SetBackdropColor(unpack(m3.surfaceContainerLow or { 0.06, 0.13, 0.15, 0.95 }))
                cb:SetBackdropBorderColor(unpack(m3.outline or { 0.31, 0.36, 0.38, 0.70 }))
                text:SetTextColor(unpack(m3.onSurface or { 0.90, 0.92, 0.95, 1.0 }))
            end
            check:Hide()
        end
    end

    local isChecked = (initialChecked and true or false)
    cb:SetChecked(isChecked)
    UpdateVisuals(isChecked, false)

    local origSetChecked = cb.SetChecked
    function cb:SetChecked(val)
        origSetChecked(self, val and true or false)
        UpdateVisuals(val and true or false, false)
    end

    local origSetEnabled = cb.SetEnabled
    function cb:SetEnabled(val)
        origSetEnabled(self, val)
        UpdateVisuals(self:GetChecked(), false)
    end

    cb:SetScript("OnEnter", function(self)
        UpdateVisuals(self:GetChecked(), true)
    end)
    cb:SetScript("OnLeave", function(self)
        UpdateVisuals(self:GetChecked(), false)
    end)

    cb:SetScript("OnClick", function(self)
        local cur = self:GetChecked()
        if PlaySound and SOUNDKIT then
            PlaySound(cur and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        end
        UpdateVisuals(cur, false)
        if onClick then
            onClick(cur)
        end
    end)

    -- Allow clicking on the text label to toggle the checkbox
    local textClicker = CreateFrame("Button", nil, cb)
    textClicker:SetPoint("TOPLEFT", text, "TOPLEFT", -2, 2)
    textClicker:SetPoint("BOTTOMRIGHT", text, "BOTTOMRIGHT", 2, -2)
    textClicker:SetScript("OnClick", function()
        if cb:IsEnabled() then
            local cur = not cb:GetChecked()
            cb:SetChecked(cur)
            if PlaySound and SOUNDKIT then
                PlaySound(cur and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
            end
            UpdateVisuals(cur, false)
            if onClick then
                onClick(cur)
            end
        end
    end)
    textClicker:SetScript("OnEnter", function()
        if cb:IsEnabled() then UpdateVisuals(cb:GetChecked(), true) end
    end)
    textClicker:SetScript("OnLeave", function()
        if cb:IsEnabled() then UpdateVisuals(cb:GetChecked(), false) end
    end)

    return cb
end

-- Helper to create modern flat dark buttons
function DQ.UI:CreateFlatButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    local m3 = (DQ.Theme and DQ.Theme.M3) or {}
    local fontPath = (DQ.Theme and DQ.Theme.GetFont and DQ.Theme.GetFont("semibold")) or "Fonts\\FRIZQT__.TTF"

    btn:SetBackdropColor(unpack(m3.surfaceContainerHigh or { 0.22, 0.28, 0.31, 0.95 }))
    btn:SetBackdropBorderColor(unpack(m3.outline or { 0.31, 0.36, 0.38, 0.55 }))

    local fontString = btn:CreateFontString(nil, "OVERLAY")
    fontString:SetFont(fontPath, 11, "")
    fontString:SetShadowOffset(0, 0)
    fontString:SetTextColor(unpack(m3.onSurface or { 0.90, 0.91, 0.94, 1.0 }))
    fontString:SetPoint("CENTER")
    fontString:SetText(text)
    btn.text = fontString

    function btn:SetButtonText(txt)
        if self.SetText then self:SetText(txt) end
        if self.text then self.text:SetText(txt) end
    end

    btn:SetScript("OnEnter", function(self)
        if not self.isSkinned then
            self:SetBackdropColor(0.28, 0.34, 0.38, 1)
            self:SetBackdropBorderColor(unpack(m3.primary or { 0.0, 0.90, 1.0, 1 }))
            if self.text then self.text:SetTextColor(1, 1, 1, 1) end
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if not self.isSkinned then
            self:SetBackdropColor(unpack(m3.surfaceContainerHigh or { 0.22, 0.28, 0.31, 0.95 }))
            self:SetBackdropBorderColor(unpack(m3.outline or { 0.31, 0.36, 0.38, 0.55 }))
            if self.text then self.text:SetTextColor(unpack(m3.onSurface or { 0.90, 0.91, 0.94, 1.0 })) end
        end
    end)

    return btn
end

-- Dedicated Toggle Button for Compatibility choices (persists highlight and never clears on hover)
function DQ.UI:CreateChoiceButton(parent, width, height, choiceType)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    btn.choiceType = choiceType -- "DistractionQoL" or "External"
    btn.isSelected = false
    btn.baseText = ""

    -- Visual check indicator (WoW built-in ready check texture, always supported on all fonts)
    local checkIcon = btn:CreateTexture(nil, "OVERLAY")
    checkIcon:SetSize(13, 13)
    checkIcon:SetPoint("LEFT", btn, "LEFT", 5, 0)
    checkIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    checkIcon:Hide()
    btn.checkIcon = checkIcon

    local fontPath = (DQ.Theme and DQ.Theme.GetFont and DQ.Theme.GetFont("semibold")) or "Fonts\\FRIZQT__.TTF"
    local fontString = btn:CreateFontString(nil, "OVERLAY")
    fontString:SetFont(fontPath, 11, "")
    fontString:SetShadowOffset(0, 0)
    btn.text = fontString

    function btn:ApplyVisuals(isHover)
        if self.isSelected then
            self.checkIcon:Show()
            self.text:ClearAllPoints()
            self.text:SetPoint("LEFT", self, "LEFT", 18, 0)
            self.text:SetPoint("RIGHT", self, "RIGHT", -4, 0)
            self.text:SetJustifyH("CENTER")
            self.text:SetWordWrap(false)

            if self.choiceType == "DistractionQoL" then
                -- Electric Cyan active state
                if isHover then
                    self:SetBackdropColor(0.0, 0.58, 0.72, 1.0)
                    self:SetBackdropBorderColor(0.30, 1.0, 1.0, 1.0)
                else
                    self:SetBackdropColor(0.0, 0.42, 0.55, 0.95)
                    self:SetBackdropBorderColor(0.0, 0.88, 1.0, 1.0)
                end
            else
                -- Royal Purple active state for external addons (Ellesmere / ElvUI)
                if isHover then
                    self:SetBackdropColor(0.55, 0.28, 0.75, 1.0)
                    self:SetBackdropBorderColor(0.90, 0.65, 1.0, 1.0)
                else
                    self:SetBackdropColor(0.42, 0.18, 0.58, 0.95)
                    self:SetBackdropBorderColor(0.78, 0.48, 1.0, 1.0)
                end
            end
            self.text:SetTextColor(1, 1, 1, 1)
            self.text:SetText(self.baseText or "")
        else
            self.checkIcon:Hide()
            self.text:ClearAllPoints()
            self.text:SetPoint("LEFT", self, "LEFT", 4, 0)
            self.text:SetPoint("RIGHT", self, "RIGHT", -4, 0)
            self.text:SetJustifyH("CENTER")
            self.text:SetWordWrap(false)

            -- Dim unselected state
            if isHover then
                self:SetBackdropColor(0.18, 0.18, 0.24, 0.95)
                self:SetBackdropBorderColor(0.45, 0.45, 0.55, 1.0)
                self.text:SetTextColor(0.95, 0.95, 0.95, 1)
            else
                self:SetBackdropColor(0.10, 0.10, 0.14, 0.85)
                self:SetBackdropBorderColor(0.22, 0.22, 0.28, 1.0)
                self.text:SetTextColor(0.60, 0.60, 0.65, 1)
            end
            self.text:SetText(self.baseText or "")
        end
    end

    function btn:SetSelected(selected, customText)
        self.isSelected = (selected == true)
        if customText ~= nil then self.baseText = customText end
        self:ApplyVisuals(false)
    end

    function btn:SetButtonText(txt)
        self.baseText = txt
        self.text:SetText(txt)
    end

    btn:SetScript("OnEnter", function(self)
        self:ApplyVisuals(true)
    end)

    btn:SetScript("OnLeave", function(self)
        self:ApplyVisuals(false)
    end)

    return btn
end

-- ==========================================================
-- MATERIAL DESIGN 3 (M3) MODERN COMPONENT FACTORIES
-- ==========================================================

-- Creates an M3 styled button (Filled, Tonal, Outlined, or Error)
function DQ.UI:CreateM3Button(parent, text, variant, width, height, iconPath)
    variant = variant or "tonal"
    width = width or 120
    height = height or 30

    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })

    local m3 = (DQ.Theme and DQ.Theme.M3) or {}
    local fontPath = (DQ.Theme and DQ.Theme.GetFont and DQ.Theme.GetFont("semibold")) or "Fonts\\FRIZQT__.TTF"

    local icon = nil
    if iconPath then
        icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", btn, "LEFT", 10, 0)
        icon:SetTexture(iconPath)
        btn.icon = icon
    end

    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont(fontPath, 12, "")
    label:SetShadowOffset(0, 0) -- Crisp zero-shadow for modern flat legibility
    if icon then
        label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        label:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
        label:SetJustifyH("CENTER")
    else
        label:SetPoint("CENTER")
    end
    label:SetText(text or "")
    btn.text = label

    function btn:ApplyM3Variant(v, isHover)
        v = v or variant
        if v == "filled" then
            -- M3 Filled Primary Button (Electric Cyan surface with crisp dark-teal text, zero shadow)
            if isHover then
                btn:SetBackdropColor(0.20, 0.95, 1.00, 1.0)
                btn:SetBackdropBorderColor(0.40, 1.00, 1.00, 1.0)
                label:SetTextColor(0.00, 0.10, 0.12, 1.0)
            else
                btn:SetBackdropColor(unpack(m3.primary or { 0.0, 0.90, 1.0, 1.0 }))
                btn:SetBackdropBorderColor(unpack(m3.primary or { 0.0, 0.90, 1.0, 1.0 }))
                label:SetTextColor(unpack(m3.onPrimary or { 0.0, 0.12, 0.15, 1.0 }))
            end
        elseif v == "tonal" then
            -- M3 Tonal Secondary Button (Material Blue Grey 800 with crisp white text)
            if isHover then
                btn:SetBackdropColor(0.28, 0.34, 0.38, 1.0)
                btn:SetBackdropBorderColor(0.40, 0.46, 0.50, 1.0)
                label:SetTextColor(1, 1, 1, 1)
            else
                btn:SetBackdropColor(unpack(m3.secondaryContainer or { 0.22, 0.28, 0.31, 0.95 }))
                btn:SetBackdropBorderColor(unpack(m3.outline or { 0.31, 0.36, 0.38, 0.55 }))
                label:SetTextColor(unpack(m3.onSecondaryContainer or { 0.90, 0.93, 0.96, 1.0 }))
            end
        elseif v == "outlined" then
            -- M3 Outlined Button (Transparent surface with subtle 1px border)
            if isHover then
                btn:SetBackdropColor(0.20, 0.25, 0.28, 0.95)
                btn:SetBackdropBorderColor(unpack(m3.primary or { 0.0, 0.90, 1.0, 1.0 }))
                label:SetTextColor(1, 1, 1, 1)
            else
                btn:SetBackdropColor(0.06, 0.13, 0.15, 0.70)
                btn:SetBackdropBorderColor(unpack(m3.outline or { 0.31, 0.36, 0.38, 0.55 }))
                label:SetTextColor(unpack(m3.onSurface or { 0.92, 0.94, 0.96, 1.0 }))
            end
        elseif v == "error" then
            -- M3 Error / Alert Button
            if isHover then
                btn:SetBackdropColor(0.48, 0.14, 0.14, 1.0)
                btn:SetBackdropBorderColor(1.0, 0.65, 0.65, 1.0)
            else
                btn:SetBackdropColor(unpack(m3.errorContainer or { 0.32, 0.10, 0.10, 0.95 }))
                btn:SetBackdropBorderColor(unpack(m3.error or { 1.0, 0.55, 0.55, 1.0 }))
            end
            label:SetTextColor(unpack(m3.onErrorContainer or { 1.0, 0.85, 0.85, 1.0 }))
        end
    end

    btn:ApplyM3Variant(variant, false)

    function btn:SetButtonText(txt)
        label:SetText(txt or "")
    end

    function btn:SetVariant(newVariant)
        variant = newVariant
        btn:ApplyM3Variant(variant, false)
    end

    btn:SetScript("OnEnter", function(self)
        if not self.isSkinned then
            self:ApplyM3Variant(variant, true)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if not self.isSkinned then
            self:ApplyM3Variant(variant, false)
        end
    end)

    return btn
end

-- Creates an M3 Icon Button (Circular / Rounded Action Button)
function DQ.UI:CreateM3IconButton(parent, iconPath, size, tooltipText, onClick)
    size = size or 28
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(size, size)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })

    local m3 = (DQ.Theme and DQ.Theme.M3) or {}
    btn:SetBackdropColor(unpack(m3.surfaceContainerHigh or { 0.22, 0.28, 0.31, 0.98 }))
    btn:SetBackdropBorderColor(unpack(m3.outlineVariant or { 0.22, 0.28, 0.31, 0.40 }))

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(size - 10, size - 10)
    icon:SetPoint("CENTER")
    icon:SetTexture(iconPath)
    btn.icon = icon

    if onClick then
        btn:SetScript("OnClick", onClick)
    end

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.28, 0.34, 0.38, 1.0)
        self:SetBackdropBorderColor(unpack(m3.primary or { 0.0, 0.90, 1.0, 1.0 }))
        if tooltipText and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tooltipText, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(m3.surfaceContainerHigh or { 0.22, 0.28, 0.31, 0.98 }))
        self:SetBackdropBorderColor(unpack(m3.outlineVariant or { 0.22, 0.28, 0.31, 0.40 }))
        if GameTooltip then GameTooltip:Hide() end
    end)

    return btn
end

-- Creates an M3 Chip / Badge (Compact pill container)
function DQ.UI:CreateM3Chip(parent, text, iconPath, variant)
    local chip = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    chip:SetHeight(20)
    chip:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })

    local m3 = (DQ.Theme and DQ.Theme.M3) or {}
    local fontPath = (DQ.Theme and DQ.Theme.GetFont and DQ.Theme.GetFont("semibold")) or "Fonts\\FRIZQT__.TTF"

    chip:SetBackdropColor(unpack(m3.primaryContainer or { 0.0, 0.28, 0.32, 0.95 }))
    chip:SetBackdropBorderColor(unpack(m3.primary or { 0.0, 0.90, 1.0, 1.0 }))

    local label = chip:CreateFontString(nil, "OVERLAY")
    label:SetFont(fontPath, 11, "")
    label:SetShadowOffset(0, 0)
    label:SetPoint("CENTER", chip, "CENTER", 0, 0)
    label:SetTextColor(unpack(m3.onPrimaryContainer or { 0.65, 0.96, 0.98, 1.0 }))
    label:SetText(text or "")
    chip.label = label

    local textWidth = label:GetStringWidth() or 30
    chip:SetWidth(textWidth + 16)

    function chip:SetChipText(t)
        label:SetText(t or "")
        local w = label:GetStringWidth() or 30
        chip:SetWidth(w + 16)
    end

    return chip
end

-- Creates an M3 Card Container (Clean surface elevation container)
function DQ.UI:CreateM3Card(parent, titleText, subtitleText, width, height)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    if width and height then
        card:SetSize(width, height)
    end

    card:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })

    local m3 = (DQ.Theme and DQ.Theme.M3) or {}
    local fontBold = (DQ.Theme and DQ.Theme.GetFont and DQ.Theme.GetFont("bold")) or "Fonts\\FRIZQT__.TTF"
    local fontRegular = (DQ.Theme and DQ.Theme.GetFont and DQ.Theme.GetFont("regular")) or "Fonts\\FRIZQT__.TTF"

    card:SetBackdropColor(unpack(m3.surfaceContainerHigh or { 0.22, 0.28, 0.31, 0.98 }))
    card:SetBackdropBorderColor(unpack(m3.outlineVariant or { 0.22, 0.28, 0.31, 0.40 }))

    if titleText then
        local title = card:CreateFontString(nil, "OVERLAY")
        title:SetFont(fontBold, 13, "")
        title:SetShadowOffset(0, 0)
        title:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -10)
        title:SetTextColor(unpack(m3.primary or { 0.0, 0.90, 1.0, 1.0 }))
        title:SetText(titleText)
        card.title = title

        if subtitleText then
            local sub = card:CreateFontString(nil, "OVERLAY")
            sub:SetFont(fontRegular, 11, "")
            sub:SetShadowOffset(0, 0)
            sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
            sub:SetPoint("RIGHT", card, "RIGHT", -12, 0)
            sub:SetJustifyH("LEFT")
            sub:SetWordWrap(true)
            sub:SetTextColor(unpack(m3.onSurfaceVariant or { 0.65, 0.70, 0.74, 1.0 }))
            sub:SetText(subtitleText)
            card.subtitle = sub
        end
    end

    return card
end
