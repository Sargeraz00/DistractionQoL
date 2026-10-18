-- SafeResurrect.lua
-- Dedicated module for post-wipe smart resurrection auto-acceptance
-- Guards against active combat to protect player positioning during Battle Rezzes

local addonName, DQ = ...

DQ.SafeResurrect = {}

local function PrintMsg(msg)
    local formatted = "|cff00e5ff[DistractionQoL]|r " .. tostring(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(formatted)
    elseif print then
        print(formatted)
    end
end

function DQ.SafeResurrect:Init()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("RESURRECT_REQUEST")

    frame:SetScript("OnEvent", function(self, event, arg1)
        local L = DQ.L or {}

        if event == "RESURRECT_REQUEST" then
            if DQ.Config:Get("automation", "autoRes", "enabled") then
                local inviter = arg1 or "Alguien"
                local inCombat = DQ.Detection and DQ.Detection.IsCombatActive and DQ.Detection:IsCombatActive()
                local allowCombat = DQ.Config:Get("automation", "autoRes", "inCombat")

                if inCombat and not allowCombat then
                    local fmt = L["MSG_AUTO_RES_BLOCKED_COMBAT"] or "Resurrección de %s recibida, pero omitida por estar en combate (Battle Rez)."
                    PrintMsg(string.format(fmt, tostring(inviter)))
                    return
                end

                -- 200ms delay to allow game engine dialog to settle safely
                C_Timer.After(0.2, function()
                    local ok, err = pcall(AcceptResurrect)
                    if ok then
                        if StaticPopup_Hide then
                            StaticPopup_Hide("RESURRECT")
                            StaticPopup_Hide("RESURRECT_NO_SICKNESS")
                            StaticPopup_Hide("RESURRECT_NO_TIMER")
                        end
                        local fmt = L["MSG_AUTO_RES_ACCEPTED"] or "Resurrección de %s aceptada automáticamente."
                        PrintMsg(string.format(fmt, tostring(inviter)))
                    end
                end)
            end
        end
    end)

    self.frame = frame
end
