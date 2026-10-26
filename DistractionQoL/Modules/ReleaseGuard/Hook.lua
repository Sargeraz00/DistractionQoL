-- Hook.lua
-- Interception module for Spirit Release dialogs and API calls
-- Fully updated for WoW 12.1.0 (Midnight) Blizzard_StaticPopup architecture
-- Strictly isolated to DEATH and DEATH_RELEASE dialogs when player is dead

local addonName, DQ = ...

DQ.Hook = {}

-- Resolves dialog frame traversing upwards from buttons or subframes (Midnight GameDialog hierarchy)
local function GetDialogFrame(btnOrDialog)
    if not btnOrDialog then return nil end
    if btnOrDialog.which then return btnOrDialog end

    local parent = btnOrDialog.GetParent and btnOrDialog:GetParent()
    while parent do
        if parent.which then
            return parent
        end
        if parent == UIParent then break end
        parent = parent.GetParent and parent:GetParent()
    end
    return nil
end

-- Resolves the active death dialog frame using modern and fallback FrameXML APIs
function DQ.Hook:GetActiveDeathDialog()
    if StaticPopup_FindVisible then
        local frame = StaticPopup_FindVisible("DEATH") or StaticPopup_FindVisible("DEATH_RELEASE")
        if frame then return frame end
    end

    if StaticPopup_Visible then
        local res = StaticPopup_Visible("DEATH") or StaticPopup_Visible("DEATH_RELEASE")
        if type(res) == "table" then
            return res
        elseif type(res) == "string" and _G[res] then
            return _G[res]
        end
    end

    for i = 1, 4 do
        local f = _G["StaticPopup" .. i]
        if f and f:IsShown() and (f.which == "DEATH" or f.which == "DEATH_RELEASE") then
            return f
        end
    end

    return nil
end

-- Strictly validates if a button or dialog belongs exclusively to the Spirit Release prompt
local function IsReleaseSpiritDialog(btnOrDialog)
    -- 1. Player condition: Must be dead/ghost or in simulation mode
    if not DQ.Detection or not DQ.Detection:IsDeadOrSim() then
        return false
    end

    -- 2. Resolve dialog frame
    local dialog = GetDialogFrame(btnOrDialog)
    if not dialog then
        return false
    end

    -- 3. Dialog type check: Must be strictly DEATH or DEATH_RELEASE
    local which = dialog.which
    if which ~= "DEATH" and which ~= "DEATH_RELEASE" then
        return false
    end

    return true
end

-- Retrieves a button from a dialog frame using Midnight's GameDialogMixin or legacy properties
function DQ.Hook:GetDialogButton(dialog, index)
    if not dialog then return nil end
    index = index or 1

    if dialog.GetButton and type(dialog.GetButton) == "function" then
        local btn = dialog:GetButton(index)
        if btn then return btn end
    end

    if index == 1 and dialog.button1 then return dialog.button1 end
    if index == 2 and dialog.button2 then return dialog.button2 end
    if index == 3 and dialog.button3 then return dialog.button3 end
    if index == 4 and dialog.button4 then return dialog.button4 end

    local name = dialog.GetName and dialog:GetName()
    if name and _G[name .. "Button" .. index] then
        return _G[name .. "Button" .. index]
    end

    return nil
end

-- Dismiss simulation preview cleanly
local function DismissSimulation(dialogFrame)
    DQ.Detection.simMode = false

    local target = GetDialogFrame(dialogFrame) or dialogFrame
    if target and target.Hide then
        target:Hide()
    end

    -- Explicitly hide all StaticPopup instances showing death dialogs
    for i = 1, 4 do
        local f = _G["StaticPopup" .. i]
        if f and (f.which == "DEATH" or f.which == "DEATH_RELEASE") then
            f:Hide()
        end
    end

    if StaticPopup_Hide then
        StaticPopup_Hide("DEATH")
        StaticPopup_Hide("DEATH_RELEASE")
    end

    local prefix = "|cff00e5ff[DistractionQoL]|r "
    local L = DQ.L or {}
    local msg = prefix .. (L["MSG_SIM_END"] or "Simulación finalizada correctamente (SHIFT+Clic detectado).")
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    elseif print then
        print(msg)
    end
end
DQ.Hook.DismissSimulation = DismissSimulation

-- Safely hooks the release button callback of a StaticPopupDialog definition
local function HookDialogDefinition(key)
    if not StaticPopupDialogs then return end
    local dialog = StaticPopupDialogs[key]
    if not dialog then return end

    dialog._BaneBurroHooked = nil

    local isIndexed = (dialog.OnButton1 ~= nil) or (dialog.selectCallbackByIndex == true)

    if isIndexed then
        -- CRITICAL FOR WOW 12.1.0: Prevent Blizzard assertion
        -- "Dialog DEATH cannot have both OnAccept and OnButton1"
        dialog.OnAccept = nil

        local origOnButton1 = dialog.OnButton1
        dialog.OnButton1 = function(self, data, reason)
            -- STRICT ISOLATION: If not death release dialog, bypass completely!
            if not IsReleaseSpiritDialog(self) then
                if origOnButton1 then return origOnButton1(self, data, reason) end
                return
            end

            if DQ.Detection and DQ.Detection:ShouldProtect() then
                local allowBypass = IsShiftKeyDown() or (DQ.WipeRelease and DQ.WipeRelease.isFullWipeActive)
                if allowBypass then
                    if DQ.Detection.simMode then
                        DismissSimulation(self)
                        return -- returns nil to allow Blizzard to hide the dialog cleanly
                    end
                    if origOnButton1 then
                        return origOnButton1(self, data, reason)
                    end
                    return
                else
                    DQ.Alert:Trigger()
                    return true -- Prevents dialog closure in Blizzard_StaticPopup
                end
            else
                if DQ.Detection.simMode then
                    DismissSimulation(self)
                    return
                end
                if origOnButton1 then
                    return origOnButton1(self, data, reason)
                end
            end
        end
    else
        dialog.OnButton1 = nil

        local origOnAccept = dialog.OnAccept
        dialog.OnAccept = function(self, data, data2)
            -- STRICT ISOLATION: If not death release dialog, bypass completely!
            if not IsReleaseSpiritDialog(self) then
                if origOnAccept then return origOnAccept(self, data, data2) end
                return
            end

            if DQ.Detection and DQ.Detection:ShouldProtect() then
                local allowBypass = IsShiftKeyDown() or (DQ.WipeRelease and DQ.WipeRelease.isFullWipeActive)
                if allowBypass then
                    if DQ.Detection.simMode then
                        DismissSimulation(self)
                        return -- returns nil to allow Blizzard to hide dialog cleanly
                    end
                    if origOnAccept then
                        return origOnAccept(self, data, data2)
                    end
                    return
                else
                    DQ.Alert:Trigger()
                    return true -- Prevents dialog closure
                end
            else
                if DQ.Detection.simMode then
                    DismissSimulation(self)
                    return
                end
                if origOnAccept then
                    return origOnAccept(self, data, data2)
                end
            end
        end
    end
end

-- Tooltip enhancements on the release button
local function HookButtonTooltip(btn)
    if not btn or btn._DQTooltipHooked then return end
    btn._DQTooltipHooked = true

    btn:HookScript("OnEnter", function(self)
        -- STRICT ISOLATION: Ignore vendor, summon, or any non-death dialogs
        if not IsReleaseSpiritDialog(self) then
            return
        end

        if DQ.Detection and DQ.Detection:ShouldProtect() then
            local L = DQ.L or {}
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(L["TOOLTIP_TITLE"] or "|cff00e5ffDistractionQoL|r")
            GameTooltip:AddLine(L["TOOLTIP_LINE1"] or "Mantén presionado |cffffcc00SHIFT|r para liberar.", 1, 1, 1)
            GameTooltip:AddLine(L["TOOLTIP_LINE2"] or "|cffff5555(¡No liberes por accidente!)|r", 1, 0.2, 0.2)
            GameTooltip:Show()
        end
    end)

    btn:HookScript("OnLeave", function(self)
        if IsReleaseSpiritDialog(self) then
            GameTooltip:Hide()
        end
    end)
end

-- Hooks UI frames and dialog instances
function DQ.Hook:HookDialogFrames()
    for i = 1, 4 do
        local f = _G["StaticPopup" .. i]
        if f and not f._DQFrameHooked then
            f._DQFrameHooked = true
            f:HookScript("OnShow", function(self)
                -- Only hook button if this instance is displaying a death dialog
                if self.which == "DEATH" or self.which == "DEATH_RELEASE" then
                    local btn1 = DQ.Hook:GetDialogButton(self, 1)
                    if btn1 then
                        HookButtonTooltip(btn1)
                    end
                end
            end)

            if f:IsShown() and (f.which == "DEATH" or f.which == "DEATH_RELEASE") then
                local btn1 = DQ.Hook:GetDialogButton(f, 1)
                if btn1 then
                    HookButtonTooltip(btn1)
                end
            end
        end
    end
end

-- Safely hooks RepopMe API
local function HookRepopMe()
    if DQ.Hook._repopHooked then return end
    DQ.Hook._repopHooked = true

    if hooksecurefunc then
        hooksecurefunc("RepopMe", function()
            -- STRICT ISOLATION: Player must be dead or in simulation
            if not DQ.Detection or not DQ.Detection:IsDeadOrSim() then
                return
            end

            if DQ.Detection and DQ.Detection:ShouldProtect() and not IsShiftKeyDown() and not DQ.Detection.simMode then
                DQ.Alert:Trigger()
            end
        end)
    end
end

-- Initialize all interception hooks
function DQ.Hook:Init()
    HookDialogDefinition("DEATH")
    HookDialogDefinition("DEATH_RELEASE")
    self:HookDialogFrames()
    HookRepopMe()
end
