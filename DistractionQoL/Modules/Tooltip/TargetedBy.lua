-- TargetedBy.lua
-- Dedicated mob tooltip raider context module
-- Displays how many party/raid members are currently targeting the hovered NPC/mob
-- Fast, event-driven, zero polling, zero continuous OnUpdate
-- Uses modern TooltipDataProcessor API (WoW 11.x / 12.1+ Midnight)
-- Fully shielded against Midnight 12.x Secret Values

local addonName, DQ = ...

DQ.TargetedBy = {}

-- Role colors
local COLOR_TANK   = "|cff00aaff" -- Cyan / Blue
local COLOR_HEALER = "|cff00ff88" -- Mint Green
local COLOR_DPS    = "|cffff5555" -- Red / Coral
local COLOR_RESET  = "|r"

-- Helper to safely check secret values in Midnight 12.x
local function IsSecret(val)
    return issecretvalue and issecretvalue(val)
end

-- Safe wrappers for WoW unit APIs to prevent secret value execution taint errors
local function SafeUnitExists(unit)
    if not unit or IsSecret(unit) then return false end
    local ok, exists = pcall(UnitExists, unit)
    return ok and exists
end

local function SafeUnitIsPlayer(unit)
    if not unit or IsSecret(unit) then return false end
    local ok, isPlayer = pcall(UnitIsPlayer, unit)
    return ok and isPlayer
end

local function SafeUnitGUID(unit)
    if not unit or IsSecret(unit) then return nil end
    local ok, guid = pcall(UnitGUID, unit)
    if ok and guid and not IsSecret(guid) then
        return guid
    end
    return nil
end

local UNIT_TOKENS = { party = {}, raid = {} }
local TARGET_TOKENS = { party = {}, raid = {} }
for i = 1, 40 do
    UNIT_TOKENS.raid[i] = "raid" .. i
    TARGET_TOKENS.raid[i] = "raid" .. i .. "target"
end
for i = 1, 4 do
    UNIT_TOKENS.party[i] = "party" .. i
    TARGET_TOKENS.party[i] = "party" .. i .. "target"
end

-- Scans group members targeting the specified mob GUID
local function GetTargetingGroupMembers(mobGUID)
    if not mobGUID or IsSecret(mobGUID) or not IsInGroup or not IsInGroup() then
        return 0, 0, 0, 0
    end

    local tankCount = 0
    local healerCount = 0
    local dpsCount = 0

    local isRaid = IsInRaid and IsInRaid()
    local prefix = isRaid and "raid" or "party"
    local count = isRaid and (GetNumGroupMembers and GetNumGroupMembers() or 0) or (GetNumSubgroupMembers and GetNumSubgroupMembers() or 0)
    local uList = UNIT_TOKENS[prefix]
    local tList = TARGET_TOKENS[prefix]

    -- In party, check player explicitly
    if not isRaid then
        local pTargetGUID = SafeUnitGUID("playertarget")
        if pTargetGUID and pTargetGUID == mobGUID then
            local role = (UnitGroupRolesAssigned and UnitGroupRolesAssigned("player")) or "NONE"
            if role == "TANK" then
                tankCount = tankCount + 1
            elseif role == "HEALER" then
                healerCount = healerCount + 1
            else
                dpsCount = dpsCount + 1
            end
        end
    end

    for i = 1, count do
        local unit = (uList and uList[i]) or (prefix .. i)
        if SafeUnitExists(unit) then
            local targetUnit = (tList and tList[i]) or (unit .. "target")
            if SafeUnitExists(targetUnit) then
                local tg = SafeUnitGUID(targetUnit)
                if tg and tg == mobGUID then
                    local role = (UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)) or "NONE"
                    if role == "TANK" then
                        tankCount = tankCount + 1
                    elseif role == "HEALER" then
                        healerCount = healerCount + 1
                    else
                        dpsCount = dpsCount + 1
                    end
                end
            end
        end
    end

    local total = tankCount + healerCount + dpsCount
    return total, tankCount, healerCount, dpsCount
end

local function OnTooltipSetUnit(tooltip, data)
    local enabled = DQ.Config and DQ.Config:Get("tooltip", "targetedBy")
    if enabled == false then return end

    if not IsInGroup or not IsInGroup() then return end

    -- Guard against secret values in data in Midnight 12.x
    if data and data.guid and IsSecret(data.guid) then return end

    -- Extract unit from tooltip
    local _, unit = tooltip:GetUnit()
    if not unit or IsSecret(unit) or not SafeUnitExists(unit) then return end

    -- Only show on NPCs/enemies (skip player characters)
    if SafeUnitIsPlayer(unit) then return end

    local mobGUID = SafeUnitGUID(unit)
    if not mobGUID or IsSecret(mobGUID) then return end

    local total, tanks, healers, dps = GetTargetingGroupMembers(mobGUID)
    if total > 0 then
        local L = DQ.L or {}
        local label = L["TOOLTIP_TARGETED_BY"] or "Enfocado por:"

        local details = {}
        if tanks > 0 then
            table.insert(details, string.format("%s%dT%s", COLOR_TANK, tanks, COLOR_RESET))
        end
        if healers > 0 then
            table.insert(details, string.format("%s%dH%s", COLOR_HEALER, healers, COLOR_RESET))
        end
        if dps > 0 then
            table.insert(details, string.format("%s%dD%s", COLOR_DPS, dps, COLOR_RESET))
        end

        local detailStr = table.concat(details, " ")
        local line = string.format("|cff00e5ff%s|r |cffffffff%d|r |cff888888(%s)|r", label, total, detailStr)

        tooltip:AddLine(line)
    end
end

function DQ.TargetedBy:Init()
    -- Modern WoW 11.x / 12.1+ TooltipDataProcessor API
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
    elseif GameTooltip then
        -- Fallback for legacy hook if TooltipDataProcessor is missing
        GameTooltip:HookScript("OnTooltipSetUnit", function(self)
            OnTooltipSetUnit(self, nil)
        end)
    end
end
