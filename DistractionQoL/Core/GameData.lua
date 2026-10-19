-- GameData.lua
-- Centralized game database, class proficiencies, slot mappings, and utility tables for DistractionQoL
-- Provides shared truth for TradeAdvisor, UtilityRadar, BagSort, and Tooltips.
-- Fully synchronized with WoW Midnight (12.x)

local addonName, DQ = ...

DQ.GameData = {}

-- Primary armor proficiencies by class (1 = Cloth, 2 = Leather, 3 = Mail, 4 = Plate)
local CLASS_ARMOR = {
    ["WARRIOR"]     = 4,
    ["PALADIN"]     = 4,
    ["DEATHKNIGHT"] = 4,
    ["HUNTER"]      = 3,
    ["SHAMAN"]      = 3,
    ["EVOKER"]      = 3,
    ["ROGUE"]       = 2,
    ["DRUID"]       = 2,
    ["MONK"]        = 2,
    ["DEMONHUNTER"] = 2,
    ["MAGE"]        = 1,
    ["PRIEST"]      = 1,
    ["WARLOCK"]     = 1,
}

-- Weapon subclass proficiencies by class
-- Enum.ItemWeaponSubclass: 0=1H Axe, 1=2H Axe, 2=Bow, 3=Gun, 4=1H Mace, 5=2H Mace,
-- 6=Polearm, 7=1H Sword, 8=2H Sword, 9=Warglaive, 10=Staff, 13=Fist, 15=Dagger, 18=Crossbow, 19=Wand
local CLASS_WEAPONS = {
    ["WARRIOR"]     = { [0]=true, [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true, [10]=true, [13]=true, [15]=true, [18]=true },
    ["PALADIN"]     = { [0]=true, [1]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true },
    ["HUNTER"]      = { [0]=true, [1]=true, [2]=true, [3]=true, [6]=true, [7]=true, [8]=true, [10]=true, [13]=true, [15]=true, [18]=true },
    ["ROGUE"]       = { [0]=true, [2]=true, [3]=true, [4]=true, [7]=true, [9]=true, [13]=true, [15]=true, [18]=true },
    ["PRIEST"]      = { [4]=true, [10]=true, [15]=true, [19]=true },
    ["DEATHKNIGHT"] = { [0]=true, [1]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true },
    ["SHAMAN"]      = { [0]=true, [1]=true, [4]=true, [5]=true, [10]=true, [13]=true, [15]=true },
    ["MAGE"]        = { [7]=true, [10]=true, [15]=true, [19]=true },
    ["WARLOCK"]     = { [7]=true, [10]=true, [15]=true, [19]=true },
    ["MONK"]        = { [0]=true, [4]=true, [6]=true, [7]=true, [10]=true, [13]=true },
    ["DRUID"]       = { [4]=true, [5]=true, [6]=true, [10]=true, [13]=true, [15]=true },
    ["DEMONHUNTER"] = { [0]=true, [7]=true, [9]=true, [13]=true },
    ["EVOKER"]      = { [0]=true, [4]=true, [7]=true, [10]=true, [13]=true, [15]=true },
}

-- Slot mapping for equipped item comparison
local SLOT_MAP = {
    ["INVTYPE_HEAD"]           = { 1 },
    ["INVTYPE_NECK"]           = { 2 },
    ["INVTYPE_SHOULDER"]       = { 3 },
    ["INVTYPE_BODY"]           = { 4 },
    ["INVTYPE_CHEST"]          = { 5 },
    ["INVTYPE_ROBE"]           = { 5 },
    ["INVTYPE_WAIST"]          = { 6 },
    ["INVTYPE_LEGS"]           = { 7 },
    ["INVTYPE_FEET"]           = { 8 },
    ["INVTYPE_WRIST"]          = { 9 },
    ["INVTYPE_HAND"]           = { 10 },
    ["INVTYPE_FINGER"]         = { 11, 12 },
    ["INVTYPE_TRINKET"]        = { 13, 14 },
    ["INVTYPE_CLOAK"]          = { 15 },
    ["INVTYPE_WEAPON"]         = { 16, 17 },
    ["INVTYPE_SHIELD"]         = { 17 },
    ["INVTYPE_2HWEAPON"]       = { 16 },
    ["INVTYPE_WEAPONMAINHAND"] = { 16 },
    ["INVTYPE_WEAPONOFFHAND"]  = { 17 },
    ["INVTYPE_HOLDABLE"]       = { 17 },
}

-- Key Raid/M+ utility classes
local LUST_CLASSES = {
    ["MAGE"]   = true,
    ["SHAMAN"] = true,
    ["EVOKER"] = true,
    ["HUNTER"] = true,
}

local BREZ_CLASSES = {
    ["WARLOCK"]     = true,
    ["DRUID"]       = true,
    ["DEATHKNIGHT"] = true,
    ["PALADIN"]     = true,
}

-- Returns the primary armor subclass (1..4) for a class
function DQ.GameData:GetArmorSubclass(classToken)
    return classToken and CLASS_ARMOR[classToken]
end

-- Returns the equipped inventory slots for an item equip location
function DQ.GameData:GetEquipmentSlots(equipLoc)
    return equipLoc and SLOT_MAP[equipLoc]
end

-- Checks if a class can equip a given item
function DQ.GameData:CanClassEquipItem(classToken, classID, subclassID, equipLoc)
    if not classToken then return false end

    -- Universal armor slots
    if equipLoc == "INVTYPE_CLOAK" or equipLoc == "INVTYPE_FINGER" or equipLoc == "INVTYPE_TRINKET" or equipLoc == "INVTYPE_NECK" then
        return true
    end

    -- Armor checks
    if classID == (Enum.ItemClass and Enum.ItemClass.Armor or 4) then
        local expected = CLASS_ARMOR[classToken]
        if expected and subclassID == expected then
            return true
        end
        -- Shields (subclass 6)
        if subclassID == 6 then
            return (classToken == "WARRIOR" or classToken == "PALADIN" or classToken == "SHAMAN")
        end
        return false
    end

    -- Weapon checks
    if classID == (Enum.ItemClass and Enum.ItemClass.Weapon or 2) then
        local allowed = CLASS_WEAPONS[classToken]
        return allowed and (allowed[subclassID] == true) or false
    end

    return false
end

-- Checks if a class provides a specific group utility
function DQ.GameData:ClassHasUtility(classToken, utilityType)
    if not classToken then return false end
    if utilityType == "lust" then
        return LUST_CLASSES[classToken] == true
    elseif utilityType == "brez" then
        return BREZ_CLASSES[classToken] == true
    end
    return false
end

-- Expose raw tables for direct lookups
DQ.GameData.CLASS_ARMOR = CLASS_ARMOR
DQ.GameData.CLASS_WEAPONS = CLASS_WEAPONS
DQ.GameData.SLOT_MAP = SLOT_MAP
DQ.GameData.LUST_CLASSES = LUST_CLASSES
DQ.GameData.BREZ_CLASSES = BREZ_CLASSES
