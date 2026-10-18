-- TargetedBy.lua
-- Dedicated mob tooltip raider context module
-- Displays how many party/raid members are currently targeting the hovered NPC/mob
-- Fast, event-driven, zero polling, zero continuous OnUpdate
-- Uses modern TooltipDataProcessor API (WoW 11.x / 12.1+ Midnight)

local addonName, DQ = ...

DQ.TargetedBy = {}

-- Role colors
local COLOR_TANK   = "|cff00aaff" -- Cyan / Blue
local COLOR_HEALER = "|cff00ff88" -- Mint Green
local COLOR_DPS    = "|cffff5555" -- Red / Coral
local COLOR_RESET  = "|r"

-- Scans group members targeting the specified mob GUID
local function GetTargetingGroupMembers(mobGUID)
    if not mobGUID or not IsInGroup or not IsInGroup() then return 0, 0, 0, 0 end

    local tankCount = 0
    local healerCount = 0
    local dpsCount = 0

    local isRaid = IsInRaid and IsInRaid()
    local prefix = isRaid and "raid" or "party"
    local count = isRaid and (GetNumGroupMembers and GetNumGroupMembers() or 0) or (GetNumSubgroupMembers and GetNumSubgroupMembers() or 0)

    -- In party, check player explicitly
    if not isRaid then
        if UnitGUID("playertarget") == mobGUID then
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
        local unit = prefix .. i
        if UnitExists(unit) then
            local targetUnit = unit .. "target"
            if UnitExists(targetUnit) and UnitGUID(targetUnit) == mobGUID then
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

    local total = tankCount + healerCount + dpsCount
    return total, tankCount, healerCount, dpsCount
end

local function OnTooltipSetUnit(tooltip, data)
    local enabled = DQ.Config and DQ.Config:Get("tooltip", "targetedBy")
    if enabled == false then return end

    if not IsInGroup or not IsInGroup() then return end

    -- Extract unit from tooltip
    local _, unit = tooltip:GetUnit()
    if not unit or not UnitExists(unit) then return end

    -- Only show on NPCs/enemies (skip player characters)
    if UnitIsPlayer(unit) then return end

    local mobGUID = UnitGUID(unit)
    if not mobGUID then return end

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
        tooltip:Show()
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
