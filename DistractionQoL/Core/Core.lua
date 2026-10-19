-- Core.lua
-- Main lifecycle coordinator and Slash command entrypoint for DistractionQoL
-- Fully updated for WoW 12.1.5 (Midnight)

local addonName, DQ = ...

-- Register all functional modules with execution priority
DQ:RegisterModule("Migration",       DQ.Migration,       10)
DQ:RegisterModule("Config",          DQ.Config,          20)
DQ:RegisterModule("Hook",            DQ.Hook,            30)
DQ:RegisterModule("RaidFlow",        DQ.RaidFlow,        100)
DQ:RegisterModule("Automation",      DQ.Automation,      100)
DQ:RegisterModule("Optimizer",       DQ.Optimizer,       100)
DQ:RegisterModule("BagSort",         DQ.BagSort,         100)
DQ:RegisterModule("ChatHistory",     DQ.ChatHistory,     100)
DQ:RegisterModule("Keystone",        DQ.Keystone,        100)
DQ:RegisterModule("WipeRelease",     DQ.WipeRelease,     100)
DQ:RegisterModule("TargetedBy",      DQ.TargetedBy,      100)
DQ:RegisterModule("ItemCounts",      DQ.ItemCounts,      100)
DQ:RegisterModule("TradeAdvisor",    DQ.TradeAdvisor,    100)
DQ:RegisterModule("UtilityRadar",    DQ.UtilityRadar,    100)
DQ:RegisterModule("CommandHub",      DQ.CommandHub,      100)
DQ:RegisterModule("SettingsCategory", {
    Init = function()
        if DQ.UI and DQ.UI.RegisterSettingsCategory then
            DQ.UI:RegisterSettingsCategory()
        end
    end
}, 200)

-- ==========================================================
-- EVENT LIFECYCLE MANAGEMENT
-- ==========================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and (arg1 == addonName or arg1 == "DistractionQoL" or arg1 == "BaneBurroReminder") then
        DQ:InitializeModules()

    elseif event == "PLAYER_LOGIN" then
        if DQ.UI and DQ.UI.CheckSkinning then
            DQ.UI:CheckSkinning()
        end
        if DQ.Wizard and DQ.Wizard.CheckAutoRun then
            DQ.Wizard:CheckAutoRun()
        end
        local L = DQ.L or {}
        local ver = (DQ.Util and DQ.Util.GetVersion and DQ.Util.GetVersion()) or "4.0.0"
        DQ:Print(string.format(L["MSG_LOADED"] or "Addon cargado (v%s - WoW Midnight). Escribe |cffffcc00/qol|r para abrir el panel.", ver))
    end
end)

-- ==========================================================
-- SLASH COMMAND REGISTRATION
-- ==========================================================
SLASH_DISTRACTIONQOL1 = "/qol"
SLASH_DISTRACTIONQOL2 = "/dqol"
SLASH_DISTRACTIONQOL3 = "/distraction"
SLASH_DISTRACTIONQOL4 = "/burro" -- Meme command alias!
SLASH_BANEBURRO1 = "/baneburro"
SLASH_BBR1 = "/bbr"

local function HandleSlashCmd(msg)
    if DQ.HandleSlashCommand then
        DQ:HandleSlashCommand(msg)
    end
end

SlashCmdList["DISTRACTIONQOL"] = HandleSlashCmd
SlashCmdList["BANEBURRO"] = HandleSlashCmd
SlashCmdList["BANEBURROREMINDER"] = HandleSlashCmd
SlashCmdList["BBR"] = HandleSlashCmd
