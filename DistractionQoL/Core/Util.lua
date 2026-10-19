-- Util.lua
-- Centralized shared utilities and helper functions for DistractionQoL
-- Safe against taint, combat lockdown, and WoW Midnight (12.x) secret values.

local addonName, DQ = ...

DQ.Util = DQ.Util or {}

-- Dynamic Addon Version from TOC
function DQ.Util.GetVersion()
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        local ver = C_AddOns.GetAddOnMetadata(addonName, "Version")
        if ver and ver ~= "" then return ver end
    end
    return "4.0.0"
end

-- Centralized safe chat printer
function DQ:Print(msg)
    local formatted = "|cff00e5ff[DistractionQoL]|r " .. tostring(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(formatted)
    elseif print then
        print(formatted)
    end
end

-- Secret value checker for WoW 12.x Midnight
function DQ.Util.IsSecret(val)
    return issecretvalue and issecretvalue(val)
end

-- Checks if combat lockdown is active
function DQ.Util.IsCombat()
    return InCombatLockdown and InCombatLockdown()
end

-- Extracts short name without realm (e.g. "Player-Realm" -> "Player")
function DQ.Util.ShortName(name)
    if not name then return "" end
    return name:match("^([^-]+)") or name
end

-- Returns name formatted with class color
function DQ.Util.ClassColorName(name, classToken)
    if not name then return "" end
    local short = DQ.Util.ShortName(name)
    if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
        local cc = RAID_CLASS_COLORS[classToken]
        return string.format("|cff%02x%02x%02x%s|r", cc.r * 255, cc.g * 255, cc.b * 255, short)
    end
    return short
end

-- Safely loads and toggles the Great Vault frame from anywhere
function DQ.Util.ToggleGreatVault()
    if not C_AddOns.IsAddOnLoaded("Blizzard_WeeklyRewards") then
        C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
    end
    if WeeklyRewardsFrame then
        WeeklyRewardsFrame:SetShown(not WeeklyRewardsFrame:IsShown())
    end
end

-- Creates a debounced function wrapper
function DQ.Util.Debounce(delaySeconds, func)
    local timer = nil
    return function(...)
        local args = { ... }
        if timer then timer:Cancel() end
        timer = C_Timer.NewTimer(delaySeconds, function()
            timer = nil
            func(unpack(args))
        end)
    end
end
