-- mock_wow.lua
-- Minimal WoW environment mocks for offline testing of DistractionQoL logic modules
-- Allows tests to run instantly under standalone lua.exe without the WoW game client.

local M = {}

-- WoW Global Enums
_G.Enum = _G.Enum or {
    ItemClass = {
        Consumable      = 0,
        Container       = 1,
        Weapon          = 2,
        Gem             = 3,
        Armor           = 4,
        Reagent         = 5,
        Projectile      = 6,
        Tradegoods      = 7,
        ItemEnhancement = 8,
        Recipe          = 9,
        CurrencyToken   = 10,
        Questitem       = 12,
        Key             = 13,
        Miscellaneous   = 15,
        Glyph           = 16,
        Battlepet       = 17,
        Profession      = 19,
    }
}

-- RAID_CLASS_COLORS
_G.RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS or {
    ["WARRIOR"]     = { r = 0.78, g = 0.61, b = 0.43 },
    ["PALADIN"]     = { r = 0.96, g = 0.55, b = 0.73 },
    ["HUNTER"]      = { r = 0.67, g = 0.83, b = 0.45 },
    ["ROGUE"]       = { r = 1.00, g = 0.96, b = 0.41 },
    ["PRIEST"]      = { r = 1.00, g = 1.00, b = 1.00 },
    ["DEATHKNIGHT"] = { r = 0.77, g = 0.12, b = 0.23 },
    ["SHAMAN"]      = { r = 0.00, g = 0.44, b = 0.87 },
    ["MAGE"]        = { r = 0.25, g = 0.78, b = 0.92 },
    ["WARLOCK"]     = { r = 0.53, g = 0.53, b = 0.93 },
    ["MONK"]        = { r = 0.00, g = 1.00, b = 0.59 },
    ["DRUID"]       = { r = 1.00, g = 0.49, b = 0.04 },
    ["DEMONHUNTER"] = { r = 0.64, g = 0.19, b = 0.79 },
    ["EVOKER"]      = { r = 0.20, g = 0.58, b = 0.50 },
}

-- C_Item stubs
_G.C_Item = _G.C_Item or {
    GetItemInfo = function(id) return nil end,
    GetItemInfoInstant = function(id) return nil end,
    GetDetailedItemLevelInfo = function(link) return 0 end,
}

-- C_Container stubs
_G.C_Container = _G.C_Container or {
    GetContainerNumSlots = function(bag) return 0 end,
    GetContainerItemInfo = function(bag, slot) return nil end,
}

-- Utility stubs
_G.GetLocale = _G.GetLocale or function() return "esES" end
_G.issecretvalue = _G.issecretvalue or function(v) return false end
_G.InCombatLockdown = _G.InCombatLockdown or function() return false end
_G.UnitClass = _G.UnitClass or function(unit) return "Paladín", "PALADIN" end
_G.UnitName = _G.UnitName or function(unit) return "Tester" end

return M
