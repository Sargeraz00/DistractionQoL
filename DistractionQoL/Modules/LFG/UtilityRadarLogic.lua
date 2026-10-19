-- UtilityRadarLogic.lua
-- Pure composition analysis logic for LFG groups and utility tracking
-- Evaluates Bloodlust, Battle Resurrection, class saturation, and invitation probability.
-- Decoupled from Blizzard UI frame structures for offline testability.

local addonName, DQ = ...

DQ.UtilityRadarLogic = {}

-- Evaluates group members for key combat utilities and recommendation
function DQ.UtilityRadarLogic.EvaluateGroup(members, playerClass, highlightEnabled)
    local lustClasses = (DQ.GameData and DQ.GameData.LUST_CLASSES) or {
        ["MAGE"] = true, ["SHAMAN"] = true, ["EVOKER"] = true, ["HUNTER"] = true,
    }
    local brezClasses = (DQ.GameData and DQ.GameData.BREZ_CLASSES) or {
        ["WARLOCK"] = true, ["DRUID"] = true, ["DEATHKNIGHT"] = true, ["PALADIN"] = true,
    }

    local playerProvidesLust = lustClasses[playerClass] or false
    local playerProvidesBrez = brezClasses[playerClass] or false

    local hasLust = false
    local hasBrez = false
    local lustProviderName = nil
    local brezProviderName = nil
    local myClassCount = 0
    local numMembers = #members

    for _, member in ipairs(members) do
        local token = member.classToken
        local locName = member.classLocalized or token

        if token then
            if lustClasses[token] then
                hasLust = true
                lustProviderName = locName
            end
            if brezClasses[token] then
                hasBrez = true
                brezProviderName = locName
            end
            if token == playerClass then
                myClassCount = myClassCount + 1
            end
        end
    end

    -- Recommendation logic: group is 3/5 or 4/5, lacks BL/CR and player provides it
    local isRecommended = false
    if highlightEnabled ~= false and numMembers >= 3 and numMembers < 5 then
        if (not hasLust and playerProvidesLust) or (not hasBrez and playerProvidesBrez) then
            isRecommended = true
        end
    end

    return {
        numMembers         = numMembers,
        hasLust            = hasLust,
        hasBrez            = hasBrez,
        lustProviderName   = lustProviderName,
        brezProviderName   = brezProviderName,
        myClassCount       = myClassCount,
        playerProvidesLust = playerProvidesLust,
        playerProvidesBrez = playerProvidesBrez,
        isRecommended      = isRecommended,
    }
end
