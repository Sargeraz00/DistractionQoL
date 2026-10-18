-- Components.lua
-- Reusable UI primitives and widgets for DistractionQoL
-- Clean flat obsidian styling, accessible checkboxes, and persistent choice toggles

local addonName, DQ = ...

DQ.UI = DQ.UI or {}

-- Helper to dynamically resolve sound icon texture path regardless of folder name
local resolvedSoundDir = nil
function DQ.UI:ResolveSoundPath(isOn)
    local file = isOn and "sound_on" or "sound_off"
    if not resolvedSoundDir then
        local testTex = UIParent:CreateTexture()
        if testTex:SetTexture("Interface\\AddOns\\" .. addonName .. "\\" .. file) then
            resolvedSoundDir = "Interface\\AddOns\\" .. addonName .. "\\"
        elseif testTex:SetTexture("Interface\\AddOns\\DistractionQoL\\" .. file) then
            resolvedSoundDir = "Interface\\AddOns\\DistractionQoL\\"
        else
            resolvedSoundDir = "Interface\\AddOns\\" .. addonName .. "\\"
        end
    end
    return resolvedSoundDir .. file
end

function DQ.UI:GetSoundIcon(isOn, size)
    size = size or 14
    local path = self:ResolveSoundPath(isOn)
    return string.format("|T%s:%d:%d:0:0|t ", path, size, size)
end

-- Helper to create CheckButtons using standard WoW template with clean positioning
function DQ.UI:CreateCheckbox(parent, label, x, y, initialChecked, onClick)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetSize(22, 22)
    cb:SetChecked(initialChecked and true or false)

    local text = cb.text or (cb:GetName() and _G[cb:GetName() .. "Text"])
    if not text then
        text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        cb.text = text
    end
    text:SetText(label)

    cb:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        if onClick then
            onClick(isChecked)
        end
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
    btn:SetBackdropColor(0.12, 0.12, 0.16, 0.95)
    btn:SetBackdropBorderColor(0.24, 0.24, 0.30, 1)

    local fontString = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fontString:SetPoint("CENTER")
    fontString:SetText(text)
    btn.text = fontString

    function btn:SetButtonText(txt)
        if self.SetText then self:SetText(txt) end
        if self.text then self.text:SetText(txt) end
    end

    btn:SetScript("OnEnter", function(self)
        if not self.isSkinned then
            self:SetBackdropColor(0.18, 0.18, 0.24, 1)
            self:SetBackdropBorderColor(0.0, 0.85, 0.95, 1)
            if self.text then self.text:SetTextColor(1, 1, 1, 1) end
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if not self.isSkinned then
            self:SetBackdropColor(0.12, 0.12, 0.16, 0.95)
            self:SetBackdropBorderColor(0.24, 0.24, 0.30, 1)
            if self.text then self.text:SetTextColor(0.9, 0.9, 0.9, 1) end
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

    local fontString = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
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
