-- TradeAdvisorLogic.lua
-- Pure loot analysis and upgrade calculation logic for TradeAdvisor
-- Evaluates item wearability by player class and determines ilvl upgrade differentials.
-- Decoupled from UI frames and network events for offline testability.

local addonName, DQ = ...

DQ.TradeAdvisorLogic = {}

-- Evaluates if an item is an upgrade based on equipped slot item levels
function DQ.TradeAdvisorLogic.EvaluateDrop(dropData, playerClass, lowestEquippedIlvl)
    local classID = dropData.classID
    local subclassID = dropData.subclassID
    local equipLoc = dropData.equipLoc
    local effectiveIlvl = dropData.itemLevel or 0

    local isWearable = false
    if DQ.GameData and DQ.GameData.CanClassEquipItem then
        isWearable = DQ.GameData:CanClassEquipItem(playerClass, classID, subclassID, equipLoc)
    else
        isWearable = true
    end

    local isUpgrade = false
    local ilvlDiff = 0

    if isWearable and lowestEquippedIlvl and lowestEquippedIlvl > 0 then
        if effectiveIlvl > lowestEquippedIlvl then
            isUpgrade = true
            ilvlDiff = effectiveIlvl - lowestEquippedIlvl
        end
    elseif isWearable and lowestEquippedIlvl == 0 and effectiveIlvl > 0 then
        -- Empty equipment slot
        isUpgrade = true
        ilvlDiff = effectiveIlvl
    end

    return {
        isWearable = isWearable,
        isUpgrade  = isUpgrade,
        ilvlDiff   = ilvlDiff,
    }
end
