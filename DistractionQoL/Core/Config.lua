-- Config.lua
-- Centralized configuration store and SavedVariables persistence for DistractionQoL

local addonName, DQ = ...

DQ.Config = {}

-- Comprehensive default configuration settings
local defaultSettings = {
    -- 1. Anti-Release (BaneBurro Guard)
    releaseGuard = {
        dungeons = true,      -- 5-man dungeons (M+, Heroic)
        raids = {
            enabled = true,   -- Master toggle for raids
            normal = true,    -- Normal raid difficulty
            heroic = true,    -- Heroic raid difficulty
            mythic = true,    -- Mythic raid difficulty
        },
        openWorld = false,    -- Open World (outside instances)
        soundEnabled = true,  -- Master toggle for audio alert
        soundChoice = "auto", -- "auto" (Bane if Distraction guild on Quel'Thalas, else Raid Warning), "raid_warning", "alarm", "bell", "bane"
    },

    -- 2. Raid Flow & Readiness (Anti-Distraction)
    raidFlow = {
        flashTaskbar = true,       -- Flash Windows taskbar icon on Ready Check / Pull
        readyCheckSound = true,    -- Play audio ping via Master channel on Ready Check
        checkConsumables = true,   -- Alert missing Flask, Food, Rune, Weapon oil at Ready Check
    },

    -- 3. QoL Automations
    automation = {
        autoRes = {
            enabled = true,        -- Auto-accept resurrection after wipe
            inCombat = false,      -- Allow Battle Rez auto-accept during combat
        },
        autoRepair = true,         -- Auto-repair gear at vendors
        guildRepair = true,        -- Use guild funds for repairs if allowed
        autoSellJunk = true,       -- Auto-sell grey trash items at vendors
        autoSkipCinematics = true, -- Auto-skip watched cinematics and movies
        blockDuels = true,         -- Block duel requests inside instances
        fastLoot = true,           -- Instant zero-delay loot pickup
        bagSortButton = true,         -- Show reverse bag sort & reagent stash button on native bags
        overrideEllesmereSort = true, -- Replace EllesmereUI sort button with DistractionQoL
    },

    -- 4. Raid Performance & Graphics
    fps = {
        optimized = false,         -- Whether optimal raid graphics mode is active
        cleanLoadingGC = true,     -- Clean Lua garbage on loading screens to prevent combat stutter
        backup = {},               -- Saved original graphics CVars
    },

    -- 5. External Addon Conflicts (EllesmereUI, ElvUI)
    conflicts = {
        choices = {},              -- [featureKey] = "DistractionQoL" or "External"
        dontAskAgain = {},         -- [featureKey] = true/false
    },

    -- 6. Chat History (Arrow Up / Down)
    chat = {
        historySize = 30,          -- Max commands remembered in circular buffer
    },

    -- 7. Mythic+ Utilities
    mythicPlus = {
        autoSlot = true,           -- Auto-insert keystone at Font of Power
        announceSlot = true,       -- Announce inserted keystone to group
    },

    -- 8. Setup Wizard State
    installerVersion = 0,          -- Version of the completed setup wizard (0 = needs wizard)
}

-- Recursively copy missing defaults into target table
local function CopyDefaults(src, dest)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dest[k]) ~= "table" then
                dest[k] = {}
            end
            CopyDefaults(v, dest[k])
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
end

-- Migrate legacy flat or BaneBurro database if present
local function MigrateLegacyDB(db)
    if not db then return end

    -- Migrate legacy flat release guard settings
    if db.dungeons ~= nil and db.releaseGuard == nil then
        db.releaseGuard = {
            dungeons = db.dungeons,
            raids = db.raids or { enabled = true, normal = true, heroic = true, mythic = true },
            openWorld = db.openWorld or false,
            soundEnabled = db.soundEnabled ~= false,
        }
        db.dungeons = nil
        db.raids = nil
        db.openWorld = nil
        db.soundEnabled = nil
    end

    -- Migrate legacy autoRes into automation
    if db.autoRes ~= nil and (not db.automation or not db.automation.autoRes) then
        if not db.automation then db.automation = {} end
        db.automation.autoRes = db.autoRes
        db.autoRes = nil
    end
end

-- Initialize database on ADDON_LOADED
function DQ.Config:Init()
    if not DistractionQoLDB then
        if BaneBurroReminderDB then
            DistractionQoLDB = BaneBurroReminderDB
        else
            DistractionQoLDB = {}
        end
    end

    MigrateLegacyDB(DistractionQoLDB)
    CopyDefaults(defaultSettings, DistractionQoLDB)
    self.db = DistractionQoLDB
end

-- Retrieve a configuration value with support for nested keys and flat convenience fallbacks
function DQ.Config:Get(section, key, subKey)
    if not self.db then return nil end

    -- Flat single-key call: e.g. Config:Get("soundEnabled") or Config:Get("autoRepair")
    if key == nil then
        if self.db[section] ~= nil then
            return self.db[section]
        end
        -- Fallback to releaseGuard
        if self.db.releaseGuard and self.db.releaseGuard[section] ~= nil then
            return self.db.releaseGuard[section]
        end
        -- Fallback to automation
        if self.db.automation and self.db.automation[section] ~= nil then
            return self.db.automation[section]
        end
        -- Fallback to raidFlow
        if self.db.raidFlow and self.db.raidFlow[section] ~= nil then
            return self.db.raidFlow[section]
        end
        -- Fallback to fps
        if self.db.fps and self.db.fps[section] ~= nil then
            return self.db.fps[section]
        end
        return nil
    end

    local val = self.db[section]
    if val == nil then return nil end

    if type(val) ~= "table" then return nil end
    val = val[key]
    if subKey ~= nil then
        if type(val) ~= "table" then return nil end
        return val[subKey]
    end
    return val
end

-- Set a configuration value with support for nested keys
function DQ.Config:Set(section, keyOrVal, subKeyOrVal, finalVal)
    if not self.db then return end

    if finalVal ~= nil then
        -- 3 levels: section, key, subKey = finalVal
        if not self.db[section] then self.db[section] = {} end
        if not self.db[section][keyOrVal] then self.db[section][keyOrVal] = {} end
        self.db[section][keyOrVal][subKeyOrVal] = finalVal
    elseif subKeyOrVal ~= nil then
        -- 2 levels: section, key = subKeyOrVal
        if not self.db[section] then self.db[section] = {} end
        self.db[section][keyOrVal] = subKeyOrVal
    else
        -- 1 level: section = keyOrVal
        self.db[section] = keyOrVal
    end
end
