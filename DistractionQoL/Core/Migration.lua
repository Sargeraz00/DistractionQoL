-- Migration.lua
-- Dedicated migration engine for DistractionQoL
-- Detects legacy versions of BaneBurroReminder, migrates all settings, and cleans up legacy cache/SavedVariables

local addonName, DQ = ...

DQ.Migration = {}

-- Safe print helper forwarding to DQ:Print
local function PrintMsg(msg)
    if DQ.Print then
        DQ:Print(msg)
    elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00e5ff[DistractionQoL]|r " .. tostring(msg))
    elseif print then
        print("|cff00e5ff[DistractionQoL]|r " .. tostring(msg))
    end
end

-- Aggressively cleans up any in-memory legacy BaneBurro hooks, frames, and dialog corruption
local function CleanseLegacyMemory()
    -- 1. Neutralize legacy BBR global table if it exists in memory
    if _G["BBR"] and type(_G["BBR"]) == "table" then
        if _G["BBR"].Alert then
            _G["BBR"].Alert.PlaySound = function() return false end
            _G["BBR"].Alert.Trigger = function() end
        end
        if _G["BBR"].Hook then
            _G["BBR"].Hook.Init = function() end
            _G["BBR"].Hook.GetActiveDeathDialog = function() return nil end
            _G["BBR"].Hook.HookDialogFrames = function() end
        end
        if _G["BBR"].Detection then
            _G["BBR"].Detection.ShouldProtect = function() return false end
            _G["BBR"].Detection.IsDeadOrSim = function() return false end
        end
        _G["BBR"] = nil
    end

    -- 2. Destroy legacy alert frames
    if _G["BaneBurroAlertFrame"] then
        _G["BaneBurroAlertFrame"]:Hide()
        _G["BaneBurroAlertFrame"]:SetScript("OnUpdate", nil)
        _G["BaneBurroAlertFrame"]:UnregisterAllEvents()
        _G["BaneBurroAlertFrame"] = nil
    end

    -- 3. Clean up StaticPopupDialogs to avoid "Dialog DEATH cannot have both OnAccept and OnButton1"
    if StaticPopupDialogs then
        for _, key in ipairs({"DEATH", "DEATH_RELEASE"}) do
            local d = StaticPopupDialogs[key]
            if d then
                d._BaneBurroHooked = nil
                if d.selectCallbackByIndex or d.OnButton1 then
                    d.OnAccept = nil
                end
            end
        end
    end
end

-- Run cleanse immediately on script load
CleanseLegacyMemory()

-- Executes the full migration process
function DQ.Migration:Run()
    local legacyDetected = false
    local migratedItems = 0

    -- 1. Check for legacy global SavedVariables from BaneBurroReminder
    if _G["BaneBurroReminderDB"] and type(_G["BaneBurroReminderDB"]) == "table" then
        local oldDB = _G["BaneBurroReminderDB"]

        if not DistractionQoLDB then
            DistractionQoLDB = {}
        end

        -- Migrate Release Guard settings
        if not DistractionQoLDB.releaseGuard then
            DistractionQoLDB.releaseGuard = {}
        end

        if oldDB.dungeons ~= nil then
            DistractionQoLDB.releaseGuard.dungeons = oldDB.dungeons
            legacyDetected = true
            migratedItems = migratedItems + 1
        end

        if oldDB.raids ~= nil and type(oldDB.raids) == "table" then
            DistractionQoLDB.releaseGuard.raids = {
                enabled = oldDB.raids.enabled ~= false,
                normal = oldDB.raids.normal ~= false,
                heroic = oldDB.raids.heroic ~= false,
                mythic = oldDB.raids.mythic ~= false,
            }
            legacyDetected = true
            migratedItems = migratedItems + 1
        end

        if oldDB.openWorld ~= nil then
            DistractionQoLDB.releaseGuard.openWorld = oldDB.openWorld
            legacyDetected = true
            migratedItems = migratedItems + 1
        end

        if oldDB.soundEnabled ~= nil then
            DistractionQoLDB.releaseGuard.soundEnabled = oldDB.soundEnabled
            legacyDetected = true
            migratedItems = migratedItems + 1
        end

        -- Migrate AutoRes into automation
        if oldDB.autoRes ~= nil and type(oldDB.autoRes) == "table" then
            if not DistractionQoLDB.automation then DistractionQoLDB.automation = {} end
            DistractionQoLDB.automation.autoRes = {
                enabled = oldDB.autoRes.enabled ~= false,
                inCombat = oldDB.autoRes.inCombat == true,
            }
            legacyDetected = true
            migratedItems = migratedItems + 1
        end

        -- Migrate FPS Optimizer settings & backups
        if oldDB.fps ~= nil and type(oldDB.fps) == "table" then
            if not DistractionQoLDB.fps then DistractionQoLDB.fps = {} end
            DistractionQoLDB.fps.optimized = oldDB.fps.optimized == true
            if oldDB.fps.backup and type(oldDB.fps.backup) == "table" then
                local bk = {}
                for k, v in pairs(oldDB.fps.backup) do bk[k] = v end
                DistractionQoLDB.fps.backup = bk
            end
            legacyDetected = true
            migratedItems = migratedItems + 1
        end

        -- Wipe the legacy database from memory so it no longer persists in WTF
        for k in pairs(_G["BaneBurroReminderDB"]) do
            _G["BaneBurroReminderDB"][k] = nil
        end
        _G["BaneBurroReminderDB"] = nil
    end

    -- 2. Aggressively clean up in-memory residual artifacts
    CleanseLegacyMemory()

    -- 3. Clean up any legacy flat keys from early DistractionQoLDB builds
    if DistractionQoLDB and type(DistractionQoLDB) == "table" then
        if DistractionQoLDB.dungeons ~= nil then
            if not DistractionQoLDB.releaseGuard then DistractionQoLDB.releaseGuard = {} end
            DistractionQoLDB.releaseGuard.dungeons = DistractionQoLDB.dungeons
            DistractionQoLDB.dungeons = nil
            legacyDetected = true
        end

        if DistractionQoLDB.raids ~= nil and type(DistractionQoLDB.raids) == "table" and not DistractionQoLDB.releaseGuard then
            DistractionQoLDB.releaseGuard = { raids = DistractionQoLDB.raids }
            DistractionQoLDB.raids = nil
            legacyDetected = true
        end

        if DistractionQoLDB.openWorld ~= nil then
            if not DistractionQoLDB.releaseGuard then DistractionQoLDB.releaseGuard = {} end
            DistractionQoLDB.releaseGuard.openWorld = DistractionQoLDB.openWorld
            DistractionQoLDB.openWorld = nil
            legacyDetected = true
        end

        if DistractionQoLDB.soundEnabled ~= nil then
            if not DistractionQoLDB.releaseGuard then DistractionQoLDB.releaseGuard = {} end
            DistractionQoLDB.releaseGuard.soundEnabled = DistractionQoLDB.soundEnabled
            DistractionQoLDB.soundEnabled = nil
            legacyDetected = true
        end

        if DistractionQoLDB.autoRes ~= nil and type(DistractionQoLDB.autoRes) == "table" then
            if not DistractionQoLDB.automation then DistractionQoLDB.automation = {} end
            DistractionQoLDB.automation.autoRes = DistractionQoLDB.autoRes
            DistractionQoLDB.autoRes = nil
            legacyDetected = true
        end
    end

    -- 4. Mark migration status and notify player
    if legacyDetected and not (DistractionQoLDB and DistractionQoLDB.migrationNotified) then
        if not DistractionQoLDB then DistractionQoLDB = {} end
        DistractionQoLDB.migrationNotified = true
        DistractionQoLDB.migratedFrom = "BaneBurroReminder"
        DistractionQoLDB.migrationTimestamp = time and time() or 0

        C_Timer.After(1.2, function()
            local L = DQ.L or {}
            PrintMsg(L["MSG_MIGRATION_SUCCESS"] or "¡Migración completada con éxito! Tus opciones de BaneBurroReminder han sido transferidas a DistractionQoL y los datos antiguos fueron depurados.")
        end)
    end
end
