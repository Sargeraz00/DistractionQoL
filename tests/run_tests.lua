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
LoadModule("DistractionQoL/Core/Locales.lua")
LoadModule("DistractionQoL/Core/GameData.lua")
LoadModule("DistractionQoL/Core/Config.lua")
DQ.Config:Init()
LoadModule("DistractionQoL/Modules/Compatibility/ConflictResolver.lua")
LoadModule("DistractionQoL/Modules/Loot/TradeAdvisorLogic.lua")
LoadModule("DistractionQoL/Modules/Chat/ChatHistory.lua")
LoadModule("DistractionQoL/Modules/BagSort/BagSortLogic.lua")
LoadModule("DistractionQoL/Modules/RaidFlow/ConsumablesLogic.lua")

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

assertTrue(DQ.GameData:CanClassEquipItem("EVOKER", Enum.ItemClass.Weapon, 8, "INVTYPE_2HWEAPON"), "Evoker can equip 2H Sword")
assertTrue(DQ.GameData:CanClassEquipItem("EVOKER", Enum.ItemClass.Weapon, 5, "INVTYPE_2HWEAPON"), "Evoker can equip 2H Mace")
assertTrue(DQ.GameData:CanClassEquipItem("EVOKER", Enum.ItemClass.Weapon, 1, "INVTYPE_2HWEAPON"), "Evoker can equip 2H Axe")
assertTrue(DQ.GameData:CanClassEquipItem("EVOKER", Enum.ItemClass.Weapon, 6, "INVTYPE_2HWEAPON"), "Evoker can equip Polearm")

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

-- Test 4b: Midnight Season 2 Ula'tek Mythic full 6/6 drop (344 ilvl) for high-end player (335 ilvl)
local ulatekChestDrop = {
    classID = Enum.ItemClass.Armor,
    subclassID = 4, -- Plate
    equipLoc = "INVTYPE_CHEST",
    itemLevel = 344,
}
local evalUlatek = DQ.TradeAdvisorLogic.EvaluateDrop(ulatekChestDrop, "PALADIN", 335)
assertTrue(evalUlatek.isWearable, "Ula'tek Mythic plate chest is wearable by Paladin")
assertTrue(evalUlatek.isUpgrade, "344 ilvl Ula'tek Mythic 6/6 vs 335 equipped is recognized as an upgrade")
assertEqual(evalUlatek.ilvlDiff, 9, "Ula'tek Mythic 6/6 gives exactly +9 ilvl over 335 equipped")

-- Test 4c: Midnight Season 2 Heroic trinket (328 ilvl) for high-end player (335 ilvl)
local heroicTrinketDrop = {
    classID = Enum.ItemClass.Armor,
    subclassID = 0,
    equipLoc = "INVTYPE_TRINKET",
    itemLevel = 328,
}
local evalHeroic = DQ.TradeAdvisorLogic.EvaluateDrop(heroicTrinketDrop, "PALADIN", 335)
assertTrue(evalHeroic.isWearable, "Heroic trinket is wearable by Paladin")
assertFalse(evalHeroic.isUpgrade, "328 ilvl vs 335 equipped is NOT an upgrade for a 335 player")
assertEqual(evalHeroic.ilvlDiff, 0, "ilvl differential is 0 for 328 ilvl trinket")

-- Test 5: Loot message hyperlink regex parsing
local lootChatSample = "Has recibido botín: |cffa335ee|Hitem:221021::::::::70:268::11:1:3524:::|h[Coraza de Obsidiana del Vacío]|h|r."
local parsedLink = lootChatSample:match("(|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r)")
assertEqual(parsedLink, "|cffa335ee|Hitem:221021::::::::70:268::11:1:3524:::|h[Coraza de Obsidiana del Vacío]|h|r", "Loot message regex successfully captures itemLink")

-- ========================================================
-- SUITE 3: ChatHistory Defaults & TradeAdvisor Extraction
-- ========================================================
print("\n\27[36m--- Suite 3: ChatHistory Defaults & TradeAdvisor Extraction ---\27[0m")

-- Case 1: Fresh edit box with empty history returns default /reload
local mockEditBox = {
    GetText = function() return "" end
}
local firstCmd = DQ.ChatHistory:GetNext(mockEditBox, 1)
assertEqual(firstCmd, "/reload", "Empty history fallback provides /reload first")

local secondCmd = DQ.ChatHistory:GetNext(mockEditBox, 1)
assertEqual(secondCmd, "/m", "Second history step provides /m")

local thirdCmd = DQ.ChatHistory:GetNext(mockEditBox, 1)
assertEqual(thirdCmd, "/qol", "Third history step provides /qol")

-- Case 2: Adding a custom command pushes it to top
DQ.ChatHistory:AddEntry("/pull 10")
local customMock = {
    GetText = function() return "" end
}
local recentCmd = DQ.ChatHistory:GetNext(customMock, 1)
assertEqual(recentCmd, "/pull 10", "Newly added command is retrieved at the top of history")

-- Case 3: Resilient TradeAdvisor hyperlink regex extraction
local pattern = "(|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r)"
local sample1 = "Valeria-Quel'Thalas recibe botín: |cffa335ee|Hitem:221021::::::::80:268::11:1:3524:::|h[Coraza del Alba del Vacío]|h|r."
local sample2 = "[Chat] looter got |cff0070dd|Hitem:221150:::|h[Sortija]|h|r"
assertTrue(sample1:match(pattern) ~= nil, "Captures complex Midnight hyperlink")
assertTrue(sample2:match(pattern) ~= nil, "Captures short rare hyperlink")

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
-- SUITE 5: Midnight Consumables & Mouse Wheel Cycling
-- ========================================================
print("\n\27[36m--- Suite 5: Midnight Consumables & Mouse Wheel Cycling ---\27[0m")

-- 1. Void-Touched Augment Rune (item ID 259085)
local runeCat, runePrio = DQ.ConsumablesLogic.ClassifyItem("Void-Touched Augment Rune", 259085)
assertEqual(runeCat, "RUNE", "Void-Touched Augment Rune matches RUNE category")
assertEqual(runePrio, 100, "Void-Touched Augment Rune has max priority (100)")

local runeEsCat, _ = DQ.ConsumablesLogic.ClassifyItem("Runa de Aumento Tocada por el Vacío", 259085)
assertEqual(runeEsCat, "RUNE", "Spanish Void-Touched Augment Rune matches RUNE category")

-- Older runes must NOT match
local oldRuneCat, _ = DQ.ConsumablesLogic.ClassifyItem("Draconic Augment Rune", 201325)
assertEqual(oldRuneCat, nil, "Older Draconic Augment Rune is rejected")

-- 2. Midnight Flasks (Strictly Midnight)
local f1Cat, f1Prio = DQ.ConsumablesLogic.ClassifyItem("Flask of the Shattered Sun", 250001)
assertEqual(f1Cat, "FLASK", "Flask of the Shattered Sun is FLASK")
assertEqual(f1Prio, 100, "Flask of the Shattered Sun priority is 100")

local f2Cat, f2Prio = DQ.ConsumablesLogic.ClassifyItem("Flask of the Blood Knights", 250002)
assertEqual(f2Cat, "FLASK", "Flask of the Blood Knights is FLASK")
assertEqual(f2Prio, 90, "Flask of the Blood Knights priority is 90")

local f3Cat, f3Prio = DQ.ConsumablesLogic.ClassifyItem("Flask of the Magisters", 250003)
assertEqual(f3Cat, "FLASK", "Flask of the Magisters is FLASK")
assertEqual(f3Prio, 80, "Flask of the Magisters priority is 80")

local f4Cat, f4Prio = DQ.ConsumablesLogic.ClassifyItem("Flask of Thalassian Resistance", 250004)
assertEqual(f4Cat, "FLASK", "Flask of Thalassian Resistance is FLASK")
assertEqual(f4Prio, 70, "Flask of Thalassian Resistance priority is 70")

-- Old flasks must NOT match
local oldFlaskCat, _ = DQ.ConsumablesLogic.ClassifyItem("Flask of Tempered Aggression", 212265)
assertEqual(oldFlaskCat, nil, "TWW Tempered Flask is rejected")

local dfPhialCat, _ = DQ.ConsumablesLogic.ClassifyItem("Phial of Tepid Versatility", 191341)
assertEqual(dfPhialCat, nil, "Dragonflight Phial is rejected")

-- 3. Midnight Food & Feasts
local food1Cat, food1Prio = DQ.ConsumablesLogic.ClassifyItem("Silvermoon Parade", 251001)
assertEqual(food1Cat, "FOOD", "Silvermoon Parade feast is FOOD")
assertEqual(food1Prio, 100, "Silvermoon Parade feast priority is 100")

local food2Cat, food2Prio = DQ.ConsumablesLogic.ClassifyItem("Blooming Feast", 251002)
assertEqual(food2Cat, "FOOD", "Blooming Feast is FOOD")
assertEqual(food2Prio, 95, "Blooming Feast priority is 95")

local food3Cat, food3Prio = DQ.ConsumablesLogic.ClassifyItem("Hearty Spiced Biscuits", 251003)
assertEqual(food3Cat, "FOOD", "Hearty Spiced Biscuits is FOOD")
assertEqual(food3Prio, 80, "Hearty food priority is 80")

-- 4. Midnight Weapon Enchants & Oils
local w1Cat, w1Prio = DQ.ConsumablesLogic.ClassifyItem("Thalassian Phoenix Oil", 252001)
assertEqual(w1Cat, "WEAPON", "Thalassian Phoenix Oil is WEAPON")
assertEqual(w1Prio, 100, "Thalassian Phoenix Oil priority is 100")

local w2Cat, w2Prio = DQ.ConsumablesLogic.ClassifyItem("Smuggler's Enchanted Edge", 252002)
assertEqual(w2Cat, "WEAPON", "Smuggler's Enchanted Edge is WEAPON")
assertEqual(w2Prio, 90, "Smuggler's Enchanted Edge priority is 90")

local w3Cat, w3Prio = DQ.ConsumablesLogic.ClassifyItem("Refulgent Whetstone", 252003)
assertEqual(w3Cat, "WEAPON", "Refulgent Whetstone is WEAPON")
assertEqual(w3Prio, 70, "Refulgent Whetstone priority is 70")

-- 5. Mouse Wheel CycleIndex Math
assertEqual(DQ.ConsumablesLogic.CycleIndex(1, 3, 1), 2, "Scroll up from 1/3 advances to 2")
assertEqual(DQ.ConsumablesLogic.CycleIndex(2, 3, 1), 3, "Scroll up from 2/3 advances to 3")
assertEqual(DQ.ConsumablesLogic.CycleIndex(3, 3, 1), 1, "Scroll up from 3/3 wraps around to 1")
assertEqual(DQ.ConsumablesLogic.CycleIndex(1, 3, -1), 3, "Scroll down from 1/3 wraps around to 3")
assertEqual(DQ.ConsumablesLogic.CycleIndex(3, 3, -1), 2, "Scroll down from 3/3 goes back to 2")
assertEqual(DQ.ConsumablesLogic.CycleIndex(1, 1, 1), 1, "Single item does not cycle out of bounds")

-- 5b. Aliases integrity
assertEqual(DQ.ConsumablesLogic.CycleSelection, DQ.ConsumablesLogic.CycleIndex, "CycleSelection alias points to CycleIndex")
assertEqual(DQ.ConsumablesLogic.GroupConsumablesByCategory, DQ.ConsumablesLogic.GroupBagItems, "GroupConsumablesByCategory alias points to GroupBagItems")
assertEqual(DQ.ConsumablesLogic.ScanBagItems, DQ.ConsumablesLogic.ScanPlayerBags, "ScanBagItems alias points to ScanPlayerBags")

-- 6. GroupBagItems and Sorting
local sampleBags = {
    { itemID = 250003, name = "Flask of the Magisters", count = 5 },
    { itemID = 250001, name = "Flask of the Shattered Sun", count = 2 },
    { itemID = 212265, name = "Flask of Tempered Aggression", count = 10 }, -- Old, should be ignored
    { itemID = 259085, name = "Void-Touched Augment Rune", count = 1 },
    { itemID = 252001, name = "Thalassian Phoenix Oil", count = 20 },
}

local grouped = DQ.ConsumablesLogic.GroupBagItems(sampleBags)
assertEqual(#grouped.FLASK, 2, "Grouped exactly 2 Midnight flasks (old TWW flask dropped)")
assertEqual(grouped.FLASK[1].name, "Flask of the Shattered Sun", "Highest priority flask placed first")
assertEqual(grouped.FLASK[2].name, "Flask of the Magisters", "Lower priority flask placed second")
assertEqual(#grouped.RUNE, 1, "Grouped Void-Touched Augment Rune")
assertEqual(#grouped.WEAPON, 1, "Grouped Thalassian Phoenix Oil")

-- 6b. Multi-stack consolidation
local multiStackBags = {
    { itemID = 252001, name = "Thalassian Phoenix Oil", count = 20 },
    { itemID = 252001, name = "Thalassian Phoenix Oil", count = 20 },
    { itemID = 252001, name = "Thalassian Phoenix Oil", count = 15 },
    { itemID = 252002, name = "Smuggler's Enchanted Edge", count = 10 },
}
local groupedMulti = DQ.ConsumablesLogic.GroupBagItems(multiStackBags)
assertEqual(#groupedMulti.WEAPON, 2, "Consolidated 3 stacks of Phoenix Oil into 1 distinct entry, total 2 weapons")
assertEqual(groupedMulti.WEAPON[1].count, 55, "Total count for 3 stacks of Phoenix Oil is exactly 55")

-- 7. BuildMacroText
local weaponMacro = DQ.ConsumablesLogic.BuildMacroText("WEAPON", 252001)
assertTrue(weaponMacro:find("/use item:252001") ~= nil and weaponMacro:find("%[btn:2%] 17; 16") ~= nil, "Weapon macro handles main hand 16 and off-hand 17")

local flaskMacro = DQ.ConsumablesLogic.BuildMacroText("FLASK", 250001)
assertEqual(flaskMacro, "/use item:250001", "Flask macro uses item directly")

-- ========================================================
-- SUITE 6: ConflictResolver & EllesmereUI Raid Handover
-- ========================================================
print("\n\27[36m--- Suite 6: ConflictResolver & EllesmereUI Raid Handover ---\27[0m")

local consumablesDef = DQ.ConflictResolver.DEFINITIONS.consumables
assertTrue(consumablesDef ~= nil, "Consumables conflict definition exists")
assertTrue(consumablesDef.superiority ~= nil, "Superiority metadata is defined")
assertTrue(consumablesDef.superiority.es:find("Rotación en tiempo real") ~= nil, "Spanish superiority mentions mouse wheel rotation")
assertTrue(consumablesDef.superiority.es:find("Midnight") ~= nil, "Spanish superiority mentions Midnight catalog")

-- Conflict detection with EllesmereUI
_G["EllesmereUI"] = {}
_G["EllesmereUIDB"] = { consumables = true, readyCheckConsumables = true }
assertEqual(DQ.ConflictResolver:DetectConflict("consumables"), "EllesmereUI", "Detects EllesmereUI conflict for consumables")

-- Handover application
DQ.ConflictResolver:ApplyHandover("consumables", "DistractionQoL", "EllesmereUI")
assertEqual(DQ.Config:Get("raidFlow", "checkConsumables"), true, "DistractionQoL handles consumables when chosen")
assertEqual(_G["EllesmereUIDB"].consumables, false, "EllesmereUI consumables disabled when DistractionQoL is chosen")

DQ.ConflictResolver:ApplyHandover("consumables", "External", "EllesmereUI")
assertEqual(DQ.Config:Get("raidFlow", "checkConsumables"), false, "DistractionQoL cedes consumables when External chosen")
assertEqual(_G["EllesmereUIDB"].consumables, true, "EllesmereUI re-enabled when External chosen")

-- Clean up globals
_G["EllesmereUI"] = nil
_G["EllesmereUIDB"] = nil

-- ========================================================
-- SUITE 7: Localization Integrity (esES / esMX & enUS)
-- ========================================================
print("\n\27[36m--- Suite 7: Localization Integrity (esES / esMX & enUS) ---\27[0m")
local requiredKeys = {
    "FOOD_BUFF", "FLASK_BUFF", "RUNE_BUFF", "WEAPON_BUFF",
    "MSG_MISSING_CONSUMABLES", "ALL_BUFFS_OK", "CONSUMABLES_BAR_TITLE",
    "CONSUMABLES_CAT_FLASK", "CONSUMABLES_CAT_FOOD", "CONSUMABLES_CAT_RUNE", "CONSUMABLES_CAT_WEAPON",
    "CONSUMABLES_WHEEL_CYCLE", "CONSUMABLES_DISTINCT_COUNT", "CONSUMABLES_WEAPON_CLICK_HINT",
    "CONSUMABLES_NO_STOCK", "CONSUMABLES_NO_STOCK_DESC", "CONSUMABLES_GEAR_TITLE",
    "CONSUMABLES_GEAR_MANAGED_BY", "CONSUMABLES_GEAR_HINT", "CONSUMABLES_MSG_CTRL_STATUS",
    "BTN_FPS_RESTORE",
    "SIM_TRACK_MYTHIC", "SIM_TRACK_HEROIC", "SIM_BIND_BOP", "SIM_SLOT_CHEST", "SIM_SLOT_FINGER",
    "SIM_SLOT_TRINKET", "SIM_CHEST_PLATE", "SIM_RING_NAME", "SIM_TRINKET_NAME", "SIM_ILVL_LABEL",
    "SIM_SOURCE_ULATEK"
}

-- 7.1 Verify Spanish translations (default mock is esES)
for _, key in ipairs(requiredKeys) do
    local val = DQ.L[key]
    assertTrue(val ~= nil and val ~= key, "esES/esMX key exists and is translated: " .. key)
end

-- 7.2 Verify English translations (switch locale mock to enUS)
_G.GetLocale = function() return "enUS" end
local DQ_en = {}
local function LoadModuleCustom(relativePath, targetTbl)
    local chunk, err = loadfile(relativePath)
    if not chunk then error(err) end
    chunk(addonName, targetTbl)
end
LoadModuleCustom("DistractionQoL/Core/Locales.lua", DQ_en)

for _, key in ipairs(requiredKeys) do
    local val = DQ_en.L[key]
    assertTrue(val ~= nil and val ~= key, "enUS key exists and is translated: " .. key)
end

-- Restore default mock locale
_G.GetLocale = function() return "esES" end

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
