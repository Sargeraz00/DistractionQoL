-- run_tests.lua
-- Comprehensive offline test suite for DistractionQoL business logic
-- Tests GameData proficiencies, TradeAdvisor upgrade math, LFG composition analysis, and BagSort plans.
-- Executable directly with: lua tests/run_tests.lua

-- 1. Setup mock WoW environment
require("tests.mock_wow")

local addonName = "DistractionQoL"
local DQ = {}

-- Helper to load addon files with addon arguments (addonName, DQ)
local function LoadModule(relativePath)
    local chunk, err = loadfile(relativePath)
    if not chunk then
        error("Failed to load module: " .. relativePath .. " -> " .. tostring(err))
    end
    chunk(addonName, DQ)
end

-- Load pure logic files
LoadModule("DistractionQoL/Core/GameData.lua")
LoadModule("DistractionQoL/Modules/Loot/TradeAdvisorLogic.lua")
LoadModule("DistractionQoL/Modules/LFG/UtilityRadarLogic.lua")
LoadModule("DistractionQoL/Modules/BagSort/BagSortLogic.lua")

-- Test Runner Framework
local totalTests = 0
local passedTests = 0
local failedTests = 0

local function assertEqual(actual, expected, message)
    totalTests = totalTests + 1
    if actual == expected then
        passedTests = passedTests + 1
        print(string.format("  [\27[32mPASS\27[0m] %s", message))
    else
        failedTests = failedTests + 1
        print(string.format("  [\27[31mFAIL\27[0m] %s\n         Expected: %s\n         Actual:   %s",
            message, tostring(expected), tostring(actual)))
    end
end

local function assertTrue(condition, message)
    assertEqual(condition == true, true, message)
end

local function assertFalse(condition, message)
    assertEqual(condition == false or condition == nil, true, message)
end

print("\n=======================================================")
print("  DistractionQoL — Offline Logic Test Suite")
print("=======================================================\n")

-- ========================================================
-- SUITE 1: GameData (Class proficiencies & slots)
-- ========================================================
print("\27[36m--- Suite 1: GameData (Proficiencies & Slots) ---\27[0m")

-- Armor subclass checks
assertEqual(DQ.GameData:GetArmorSubclass("WARRIOR"), 4, "Warrior armor subclass is Plate (4)")
assertEqual(DQ.GameData:GetArmorSubclass("PALADIN"), 4, "Paladin armor subclass is Plate (4)")
assertEqual(DQ.GameData:GetArmorSubclass("HUNTER"), 3, "Hunter armor subclass is Mail (3)")
assertEqual(DQ.GameData:GetArmorSubclass("SHAMAN"), 3, "Shaman armor subclass is Mail (3)")
assertEqual(DQ.GameData:GetArmorSubclass("ROGUE"), 2, "Rogue armor subclass is Leather (2)")
assertEqual(DQ.GameData:GetArmorSubclass("MAGE"), 1, "Mage armor subclass is Cloth (1)")

-- Weapon proficiency checks
assertTrue(DQ.GameData:CanClassEquipItem("WARRIOR", Enum.ItemClass.Weapon, 1, "INVTYPE_2HWEAPON"), "Warrior can equip 2H Axe")
assertTrue(DQ.GameData:CanClassEquipItem("WARRIOR", Enum.ItemClass.Weapon, 8, "INVTYPE_2HWEAPON"), "Warrior can equip 2H Sword")
assertFalse(DQ.GameData:CanClassEquipItem("WARRIOR", Enum.ItemClass.Weapon, 19, "INVTYPE_WEAPON"), "Warrior cannot equip Wand")

assertTrue(DQ.GameData:CanClassEquipItem("MAGE", Enum.ItemClass.Weapon, 19, "INVTYPE_WEAPON"), "Mage can equip Wand")
assertTrue(DQ.GameData:CanClassEquipItem("MAGE", Enum.ItemClass.Weapon, 10, "INVTYPE_2HWEAPON"), "Mage can equip Staff")
assertFalse(DQ.GameData:CanClassEquipItem("MAGE", Enum.ItemClass.Weapon, 1, "INVTYPE_2HWEAPON"), "Mage cannot equip 2H Axe")

-- Armor compatibility checks
assertTrue(DQ.GameData:CanClassEquipItem("PALADIN", Enum.ItemClass.Armor, 4, "INVTYPE_CHEST"), "Paladin can equip Plate chest")
assertFalse(DQ.GameData:CanClassEquipItem("PALADIN", Enum.ItemClass.Armor, 1, "INVTYPE_CHEST"), "Paladin cannot equip Cloth chest")
assertTrue(DQ.GameData:CanClassEquipItem("PALADIN", Enum.ItemClass.Armor, 6, "INVTYPE_SHIELD"), "Paladin can equip Shield")
assertFalse(DQ.GameData:CanClassEquipItem("ROGUE", Enum.ItemClass.Armor, 6, "INVTYPE_SHIELD"), "Rogue cannot equip Shield")

-- Universal slots
assertTrue(DQ.GameData:CanClassEquipItem("ROGUE", Enum.ItemClass.Armor, 0, "INVTYPE_CLOAK"), "Cloak is universal for Rogue")
assertTrue(DQ.GameData:CanClassEquipItem("PRIEST", Enum.ItemClass.Armor, 0, "INVTYPE_TRINKET"), "Trinket is universal for Priest")
assertTrue(DQ.GameData:CanClassEquipItem("MAGE", Enum.ItemClass.Armor, 0, "INVTYPE_FINGER"), "Ring is universal for Mage")

-- Utilities
assertTrue(DQ.GameData:ClassHasUtility("MAGE", "lust"), "Mage has Bloodlust/Heroism")
assertTrue(DQ.GameData:ClassHasUtility("SHAMAN", "lust"), "Shaman has Bloodlust/Heroism")
assertTrue(DQ.GameData:ClassHasUtility("EVOKER", "lust"), "Evoker has Bloodlust/Heroism")
assertTrue(DQ.GameData:ClassHasUtility("HUNTER", "lust"), "Hunter has Bloodlust/Heroism")
assertFalse(DQ.GameData:ClassHasUtility("WARRIOR", "lust"), "Warrior does NOT have Bloodlust")

assertTrue(DQ.GameData:ClassHasUtility("WARLOCK", "brez"), "Warlock has Battle Rez")
assertTrue(DQ.GameData:ClassHasUtility("DRUID", "brez"), "Druid has Battle Rez")
assertTrue(DQ.GameData:ClassHasUtility("DEATHKNIGHT", "brez"), "Death Knight has Battle Rez")
assertTrue(DQ.GameData:ClassHasUtility("PALADIN", "brez"), "Paladin has Battle Rez")
assertFalse(DQ.GameData:ClassHasUtility("ROGUE", "brez"), "Rogue does NOT have Battle Rez")

-- ========================================================
-- SUITE 2: TradeAdvisorLogic (Loot Drop Evaluation)
-- ========================================================
print("\n\27[36m--- Suite 2: TradeAdvisorLogic (Loot Evaluation) ---\27[0m")

-- Test 1: +20 ilvl upgrade on Paladin (Plate chest)
local drop1 = {
    classID = Enum.ItemClass.Armor,
    subclassID = 4, -- Plate
    equipLoc = "INVTYPE_CHEST",
    itemLevel = 650,
}
local eval1 = DQ.TradeAdvisorLogic.EvaluateDrop(drop1, "PALADIN", 630)
assertTrue(eval1.isWearable, "Plate chest is wearable by Paladin")
assertTrue(eval1.isUpgrade, "650 ilvl vs 630 equipped is recognized as an upgrade")
assertEqual(eval1.ilvlDiff, 20, "ilvl differential is exactly +20")

-- Test 2: Down-grade / side-grade (lower ilvl)
local drop2 = {
    classID = Enum.ItemClass.Armor,
    subclassID = 4,
    equipLoc = "INVTYPE_CHEST",
    itemLevel = 620,
}
local eval2 = DQ.TradeAdvisorLogic.EvaluateDrop(drop2, "PALADIN", 630)
assertTrue(eval2.isWearable, "Item is wearable")
assertFalse(eval2.isUpgrade, "620 ilvl vs 630 equipped is NOT an upgrade")
assertEqual(eval2.ilvlDiff, 0, "ilvl differential is 0 for non-upgrades")

-- Test 3: Incompatible armor type (Cloth drop for Paladin)
local drop3 = {
    classID = Enum.ItemClass.Armor,
    subclassID = 1, -- Cloth
    equipLoc = "INVTYPE_ROBE",
    itemLevel = 660,
}
local eval3 = DQ.TradeAdvisorLogic.EvaluateDrop(drop3, "PALADIN", 630)
assertFalse(eval3.isWearable, "Cloth robe is NOT wearable by Paladin")
assertFalse(eval3.isUpgrade, "Incompatible item is NOT flagged as upgrade")

-- Test 4: Empty equipment slot (equipped = 0)
local drop4 = {
    classID = Enum.ItemClass.Armor,
    subclassID = 0,
    equipLoc = "INVTYPE_TRINKET",
    itemLevel = 645,
}
local eval4 = DQ.TradeAdvisorLogic.EvaluateDrop(drop4, "ROGUE", 0)
assertTrue(eval4.isWearable, "Trinket is wearable by Rogue")
assertTrue(eval4.isUpgrade, "Item in empty slot is recognized as an upgrade")
assertEqual(eval4.ilvlDiff, 645, "ilvl differential matches full item level for empty slot")

-- ========================================================
-- SUITE 3: UtilityRadarLogic (LFG Composition Analysis)
-- ========================================================
print("\n\27[36m--- Suite 3: UtilityRadarLogic (LFG Composition) ---\27[0m")

-- Scenario A: Group has 4 members (Tank Warrior, Healer Priest, DPS Rogue, DPS Hunter)
-- Utilities present: Hunter brings Bloodlust. Missing: Brez!
local groupA = {
    { classToken = "WARRIOR", classLocalized = "Guerrero" },
    { classToken = "PRIEST",  classLocalized = "Sacerdote" },
    { classToken = "ROGUE",   classLocalized = "Pícaro" },
    { classToken = "HUNTER",  classLocalized = "Cazador" },
}

-- Case 1: Player is a Paladin (brings Brez!) -> High recommendation!
local resA1 = DQ.UtilityRadarLogic.EvaluateGroup(groupA, "PALADIN", true)
assertTrue(resA1.hasLust, "Group has Bloodlust (Hunter)")
assertEqual(resA1.lustProviderName, "Cazador", "Bloodlust provider correctly identified")
assertFalse(resA1.hasBrez, "Group is missing Battle Rez")
assertTrue(resA1.playerProvidesBrez, "Paladin player provides missing Battle Rez")
assertTrue(resA1.isRecommended, "Group is recommended to Paladin because it lacks Brez")

-- Case 2: Player is a Rogue (brings neither) -> Not recommended
local resA2 = DQ.UtilityRadarLogic.EvaluateGroup(groupA, "ROGUE", true)
assertFalse(resA2.isRecommended, "Group is NOT recommended to Rogue (does not provide missing utility)")
assertEqual(resA2.myClassCount, 1, "Correctly identifies 1 other Rogue already in group")

-- Case 3: Group is full (5/5)
local groupFull = {
    { classToken = "WARRIOR" }, { classToken = "PRIEST" },
    { classToken = "ROGUE" }, { classToken = "HUNTER" }, { classToken = "MAGE" }
}
local resFull = DQ.UtilityRadarLogic.EvaluateGroup(groupFull, "PALADIN", true)
assertFalse(resFull.isRecommended, "Full group (5/5) is never recommended")

-- ========================================================
-- SUITE 4: BagSortLogic (Reverse Bag Sort Algorithm)
-- ========================================================
print("\n\27[36m--- Suite 4: BagSortLogic (Reverse Sort Algorithm) ---\27[0m")

-- Scenario:
-- Regular bags: 4 slots
-- Reagent bag: 2 slots
-- Slot 0:1 = Reagent (Ore)
-- Slot 0:2 = Grey Junk (Broken Fang, quality 0)
-- Slot 0:3 = Epic Weapon (quality 4)
-- Slot 0:4 = Empty
-- Reagent Bag 5:1 = Empty
-- Reagent Bag 5:2 = Empty
local mockInventory = {
    [0] = {
        [1] = { bag = 0, slot = 1, isReagent = true, quality = 2, name = "Menas de Bismuth", itemID = 210934 },
        [2] = { bag = 0, slot = 2, isReagent = false, quality = 0, name = "Colmillo Roto", itemID = 1000 },
        [3] = { bag = 0, slot = 3, isReagent = false, quality = 4, name = "Espada del Vacío", itemID = 220000 },
    },
    [1] = {}, [2] = {}, [3] = {}, [4] = {},
    [5] = {}
}

local regularSlots = {
    { bag = 0, slot = 1 },
    { bag = 0, slot = 2 },
    { bag = 0, slot = 3 },
    { bag = 0, slot = 4 },
}

local reagentSlots = {
    { bag = 5, slot = 1 },
    { bag = 5, slot = 2 },
}

local plan = DQ.BagSortLogic.GeneratePlan(mockInventory, regularSlots, reagentSlots)

assertTrue(#plan > 0, "Sort plan generated actions")
assertEqual(plan[1].fromBag, 0, "Step 1 moves from regular bag 0")
assertEqual(plan[1].fromSlot, 1, "Step 1 moves the Reagent from slot 1")
assertEqual(plan[1].toBag, 5, "Step 1 deposits into Reagent Bag 5")
assertEqual(plan[1].toSlot, 1, "Step 1 places in Reagent Bag slot 1")

-- Verify final inventory state after plan execution:
-- Reagent is in Bag 5
assertTrue(mockInventory[5][1] ~= nil and mockInventory[5][1].isReagent, "Reagent successfully placed into Reagent Bag 5")

-- Non-reagents are placed at the BOTTOM of regular slots:
-- Slots 0:3 and 0:4 should contain the gear and grey junk, while slot 0:1 and 0:2 are clean/empty!
assertTrue(mockInventory[0][3] ~= nil, "Slot 0:3 is populated with sorted item")
assertTrue(mockInventory[0][4] ~= nil, "Slot 0:4 is populated with sorted item")
assertEqual(mockInventory[0][4].quality, 0, "Grey junk item placed at the absolute bottom (Slot 0:4)")
assertEqual(mockInventory[0][3].quality, 4, "Epic weapon placed above grey junk (Slot 0:3)")
assertEqual(mockInventory[0][1], nil, "Top of regular bags (Slot 0:1) left empty for new loot / overflow")
assertEqual(mockInventory[0][2], nil, "Top of regular bags (Slot 0:2) left empty for new loot / overflow")

-- ========================================================
-- SUMMARY
-- ========================================================
print("\n=======================================================")
if failedTests == 0 then
    print(string.format("  \27[32m✔ ALL %d TESTS PASSED SUCCESSFULLY!\27[0m", totalTests))
else
    print(string.format("  \27[31m✖ %d of %d TESTS FAILED.\27[0m", failedTests, totalTests))
end
print("=======================================================\n")

if failedTests > 0 then
    os.exit(1)
end
