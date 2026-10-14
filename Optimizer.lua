-- Optimizer.lua
-- Graphics and CVars Performance Optimizer for DistractionQoL
-- Optimizes Raid & Instance FPS while preserving essential combat visual mechanics
-- Fully reversible with instant backup & restore

local addonName, DQ = ...

DQ.Optimizer = {}

-- Safe CVar getters and setters with C_CVar / global fallbacks
local function GetCVarVal(cvar)
    if C_CVar and C_CVar.GetCVar then
        local val = C_CVar.GetCVar(cvar)
        if val ~= nil then return tostring(val) end
    end
    if GetCVar then
        local val = GetCVar(cvar)
        if val ~= nil then return tostring(val) end
    end
    return nil
end

local function SetCVarVal(cvar, val)
    local strVal = tostring(val)
    if C_CVar and C_CVar.SetCVar then
        local ok = pcall(C_CVar.SetCVar, cvar, strVal)
        if ok then return true end
    end
    if SetCVar then
        local ok = pcall(SetCVar, cvar, strVal)
        if ok then return true end
    end
    return false
end

-- Print helper using addon branding
local function PrintMsg(msg)
    local formatted = "|cff00e5ff[DistractionQoL]|r " .. tostring(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(formatted)
    elseif print then
        print(formatted)
    end
end

-- ==========================================================
-- OPTIMAL SETTINGS DEFINITION
-- ==========================================================
-- Designed specifically for Raids & Mythic+ to eliminate CPU & GPU bottlenecks
-- NOTE: Projected Textures is ALWAYS set to "1" so mechanic swirlies remain 100% visible!
local OPTIMAL_CVARS = {
    -- Enable separate Raid Graphics profile
    ["RAIDsettingsEnabled"]             = "1",

    -- Raid Graphics settings (Heavy single-thread CPU killers lowered)
    ["raidGraphicsProjectedTextures"]   = "1",  -- CRITICAL: Must be enabled to see boss mechanics on the ground!
    ["raidGraphicsShadowQuality"]       = "0",  -- Shadows off (biggest CPU geometry hog in 20-30m raid)
    ["raidGraphicsLiquidDetail"]        = "0",  -- Water reflections off
    ["raidGraphicsParticleDensity"]     = "2",  -- Fair/Medium (essential to keep spells visible without FPS drop)
    ["raidGraphicsSSAO"]                = "0",  -- Ambient occlusion off (heavy GPU/render pass cost)
    ["raidGraphicsSunshafts"]           = "0",  -- Sunshafts off
    ["raidGraphicsDepthEffects"]        = "0",  -- Depth post-processing off
    ["raidGraphicsLightingQuality"]     = "1",  -- Low lighting calculations
    ["raidGraphicsOutlineMode"]         = "1",  -- Outline mode low (keeps target highlight visible)
    ["raidGraphicsComputeEffects"]      = "0",  -- Compute shaders off
    ["raidGraphicsViewDistance"]        = "3",  -- View distance 3 (raid arenas don't need distance 10)
    ["raidGraphicsEnvironmentDetail"]   = "3",  -- Environment detail 3
    ["raidGraphicsGroundClutter"]       = "0",  -- Ground clutter/grass off in raid

    -- VFX, Combat & Engine Clutter Tweaks
    ["spellClutter"]                    = "1",  -- Modern dynamic spell clutter reduction (filters useless ally VFX)
    ["ffxGlow"]                         = "0",  -- Fullscreen glow bloom off (reduces GPU load & visual noise)
    ["weatherDensity"]                  = "0",  -- Weather particles off
    ["rippleDetail"]                    = "0",  -- Water ripples off
    ["MaxFPSBk"]                        = "30", -- Background FPS cap when alt-tabbed (saves heat & resources)
}

-- Return the list of CVars managed by the optimizer
function DQ.Optimizer:GetManagedCVars()
    return OPTIMAL_CVARS
end

-- Check if a backup exists in SavedVariables
function DQ.Optimizer:HasBackup()
    local backup = DQ.Config:Get("fps", "backup")
    if not backup or type(backup) ~= "table" then return false end
    for _ in pairs(backup) do
        return true
    end
    return false
end

-- Check if optimal mode is currently marked active
function DQ.Optimizer:IsOptimized()
    return DQ.Config:Get("fps", "optimized") == true
end

-- ==========================================================
-- BACKUP CURRENT SETTINGS
-- ==========================================================
function DQ.Optimizer:SaveBackup(silent)
    local backup = {}
    local count = 0

    for cvar, _ in pairs(OPTIMAL_CVARS) do
        local currentVal = GetCVarVal(cvar)
        if currentVal ~= nil then
            backup[cvar] = currentVal
            count = count + 1
        end
    end

    DQ.Config:Set("fps", "backup", backup)

    if not silent then
        local L = DQ.L or {}
        local fmt = L["MSG_FPS_SAVED"] or "Configuración gráfica actual guardada como copia de respaldo (%d opciones)."
        PrintMsg(string.format(fmt, count))
    end

    return count
end

-- ==========================================================
-- APPLY OPTIMAL RAID SETTINGS
-- ==========================================================
function DQ.Optimizer:ApplyOptimal()
    local L = DQ.L or {}

    -- Auto-save backup first if none exists yet
    if not self:HasBackup() then
        self:SaveBackup(true)
    end

    local appliedCount = 0
    for cvar, optimalVal in pairs(OPTIMAL_CVARS) do
        local ok = SetCVarVal(cvar, optimalVal)
        if ok then
            appliedCount = appliedCount + 1
        end
    end

    DQ.Config:Set("fps", "optimized", true)

    local fmt = L["MSG_FPS_OPTIMIZED"] or "¡Opciones de Máximo FPS para Raid aplicadas con éxito! (%d ajustes optimizados)."
    PrintMsg(string.format(fmt, appliedCount))

    if DQ.UI and DQ.UI.UpdateFPSControls then
        DQ.UI:UpdateFPSControls()
    end
end

-- ==========================================================
-- RESTORE ORIGINAL SETTINGS
-- ==========================================================
function DQ.Optimizer:RestoreOriginal()
    local L = DQ.L or {}
    local backup = DQ.Config:Get("fps", "backup")

    if not backup or type(backup) ~= "table" or not self:HasBackup() then
        PrintMsg(L["MSG_FPS_NO_BACKUP"] or "No hay una copia de respaldo guardada para restaurar.")
        return
    end

    local restoredCount = 0
    for cvar, originalVal in pairs(backup) do
        local ok = SetCVarVal(cvar, originalVal)
        if ok then
            restoredCount = restoredCount + 1
        end
    end

    DQ.Config:Set("fps", "optimized", false)

    local fmt = L["MSG_FPS_RESTORED"] or "Configuración gráfica original restaurada con éxito (%d ajustes restablecidos)."
    PrintMsg(string.format(fmt, restoredCount))

    if DQ.UI and DQ.UI.UpdateFPSControls then
        DQ.UI:UpdateFPSControls()
    end
end

-- Initializes performance event listeners
function DQ.Optimizer:Init()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            -- Clean Lua memory during loading screen to eliminate combat garbage collection latency
            if DQ.Config:Get("fps", "cleanLoadingGC") then
                collectgarbage("collect")
            end
        end
    end)

    self.frame = frame
end
