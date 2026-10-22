-- Commands.lua
-- Centralized Slash Command dispatcher and self-generating help registry for DistractionQoL
-- Fast O(1) trigger lookups, clean localized help generation, and decoupled module registration.

local addonName, DQ = ...

DQ.Commands = {}
local commandMap = {}
local commandList = {}

-- Registers a slash command
-- triggers: table of trigger strings, e.g. { "hub", "keys" } or single string "vault"
-- handler: function(arg)
-- descEs: string description in Spanish
-- descEn: string description in English
-- order: integer for sorting help output (optional)
function DQ:RegisterCommand(triggers, handler, descEs, descEn, order)
    if type(triggers) == "string" then
        triggers = { triggers }
    end
    if not triggers or #triggers == 0 or type(handler) ~= "function" then
        return
    end

    local entry = {
        primaryTrigger = triggers[1],
        triggers = triggers,
        handler = handler,
        descEs = descEs or "",
        descEn = descEn or "",
        order = order or (#commandList + 1),
    }

    table.insert(commandList, entry)
    table.sort(commandList, function(a, b) return a.order < b.order end)

    for _, tr in ipairs(triggers) do
        commandMap[tr:lower()] = entry
    end

    return entry
end

-- Displays self-generating localized command list
function DQ:PrintCommandHelp()
    local isSpanish = (GetLocale and (GetLocale() == "esES" or GetLocale() == "esMX"))
    if isSpanish then
        DQ:Print("--- |cff00e5ffDistractionQoL|r Comandos ---")
        DQ:Print("|cffffcc00/qol|r (o |cffffcc00/burro|r) - Abre el panel de configuración.")
        for _, entry in ipairs(commandList) do
            if entry.descEs and entry.descEs ~= "" then
                local aliases = table.concat(entry.triggers, "|r o |cffffcc00/qol ")
                DQ:Print(string.format("|cffffcc00/qol %s|r - %s", aliases, entry.descEs))
            end
        end
    else
        DQ:Print("--- |cff00e5ffDistractionQoL|r Commands ---")
        DQ:Print("|cffffcc00/qol|r (or |cffffcc00/burro|r) - Open configuration console.")
        for _, entry in ipairs(commandList) do
            if entry.descEn and entry.descEn ~= "" then
                local aliases = table.concat(entry.triggers, "|r or |cffffcc00/qol ")
                DQ:Print(string.format("|cffffcc00/qol %s|r - %s", aliases, entry.descEn))
            end
        end
    end
end

-- Main slash command dispatcher
function DQ:HandleSlashCommand(msg)
    local cmd, arg = (msg or ""):lower():match("^%s*(%S*)%s*(%S*)")

    if cmd == "" or cmd == "config" or cmd == "panel" then
        if DQ.UI and DQ.UI.Toggle then
            DQ.UI:Toggle()
        end
        return
    end

    if cmd == "help" or cmd == "?" then
        DQ:PrintCommandHelp()
        return
    end

    local entry = commandMap[cmd]
    if entry and entry.handler then
        entry.handler(arg)
    else
        DQ:PrintCommandHelp()
    end
end

-- Register Default Core Commands
local function InitDefaultCommands()
    local L = DQ.L or {}

    -- 1. Install Wizard
    DQ:RegisterCommand({ "install", "wizard" }, function()
        if DQ.Wizard and DQ.Wizard.Open then DQ.Wizard:Open() end
    end, "Abre el asistente de bienvenida y configuración rápida.", "Opens the first-time setup and onboarding wizard.", 10)

    -- 2. Command Hub / Keys
    DQ:RegisterCommand({ "hub", "keys" }, function()
        if DQ.CommandHub and DQ.CommandHub.Toggle then DQ.CommandHub:Toggle() end
    end, "Centro M+ (Teleports de Midnight y matriz de llaves del grupo).", "M+ Command Hub (Midnight teleports & party keystone matrix).", 20)

    -- 3. Great Vault
    DQ:RegisterCommand("vault", function()
        if DQ.Util and DQ.Util.ToggleGreatVault then DQ.Util.ToggleGreatVault() end
    end, "Abre la Gran Bóveda semanal al instante desde cualquier lugar.", "Opens the Great Vault instantly from anywhere.", 30)

    -- 4. Bag Sort
    DQ:RegisterCommand({ "sort", "bags", "bolsas" }, function()
        if DQ.BagSort and DQ.BagSort.SortBags then DQ.BagSort:SortBags() end
    end, "Ordena bolsas (inverso, materiales a bolsa de profesión).", "Sorts bags (reverse order, reagents into reagent bag).", 40)

    -- 5. Loot Advisor Test
    DQ:RegisterCommand("loot", function()
        if DQ.TradeAdvisor and DQ.TradeAdvisor.SimulateTestLoot then
            DQ:Print(L["LOOT_ADVISOR_TITLE"] or "Simulando botín de prueba...")
            DQ.TradeAdvisor:SimulateTestLoot()
        end
    end, "Simula y prueba la ventana de Asesor de Botín Comerciable.", "Simulates and tests the Tradeable Loot Advisor popup.", 50)

    -- 6. Check Consumables & Interactive Manager
    DQ:RegisterCommand({ "check", "buffs", "consumables", "consumibles", "consumible", "frascos" }, function(arg)
        if DQ.ConsumablesBar and DQ.ConsumablesBar.OpenManager then
            local forcePrompt = (arg == "choose" or arg == "setup" or arg == "prompt" or arg == "conflict" or arg == "cambiar")
            DQ.ConsumablesBar:OpenManager(forcePrompt)
        elseif DQ.RaidFlow and DQ.RaidFlow.CheckConsumables then
            DQ.RaidFlow:CheckConsumables(true)
        end
    end, "Abre el gestor de consumibles interactivo y selector de control.", "Opens interactive consumables HUD and feature controller.", 60)

    -- 7. Consumables Conflict Resolver
    DQ:RegisterCommand({ "conflict", "conflicts", "compat", "compatibility" }, function()
        if DQ.ConsumablesBar and DQ.ConsumablesBar.OpenManager then
            DQ.ConsumablesBar:OpenManager(true)
        elseif DQ.RaidFlow and DQ.RaidFlow.CheckRaidConsumablesConflict then
            DQ.RaidFlow:CheckRaidConsumablesConflict(true)
        end
    end, "Abre el diálogo de elección de gestor (DistractionQoL vs EllesmereUI).", "Opens manager choice dialog (DistractionQoL vs EllesmereUI).", 65)

    -- 7. FPS Optimizer
    DQ:RegisterCommand("fps", function(arg)
        if not DQ.Optimizer then return end
        if arg == "save" or arg == "backup" then
            DQ.Optimizer:SaveBackup()
        elseif arg == "opt" or arg == "on" or arg == "max" then
            DQ.Optimizer:ApplyOptimal()
        elseif arg == "restore" or arg == "off" or arg == "reset" then
            DQ.Optimizer:RestoreOriginal()
        else
            if DQ.Optimizer:IsOptimized() then
                DQ.Optimizer:RestoreOriginal()
            else
                DQ.Optimizer:ApplyOptimal()
            end
        end
    end, "Alterna entre Máximo FPS para Raid y ajustes originales (o usa 'save'/'restore').", "Toggles between Optimal Raid FPS and original settings (or use 'save'/'restore').", 70)

    -- 8. Audio Mute
    DQ:RegisterCommand("mute", function()
        local current = DQ.Config:Get("releaseGuard", "soundEnabled") ~= false
        local newVal = not current
        DQ.Config:Set("releaseGuard", "soundEnabled", newVal)
        local icon = newVal and ("|TInterface\\AddOns\\" .. addonName .. "\\sound_on:14:14:0:0|t ")
                             or  ("|TInterface\\AddOns\\" .. addonName .. "\\sound_off:14:14:0:0|t ")
        local statusMsg = newVal and (L["MSG_MUTE_OFF"] or "Sonido de alerta: |cff00ff00ACTIVADO|r") or (L["MSG_MUTE_ON"] or "Sonido de alerta: |cffff3333SILENCIADO (MUTE)|r")
        DQ:Print(icon .. statusMsg)
        if DQ.UI and DQ.UI.UpdateSoundControls then DQ.UI:UpdateSoundControls() end
    end, "Silencia o activa el sonido de alerta.", "Mutes or unmutes the alert sound.", 80)

    -- 9. Auto-Resurrection
    DQ:RegisterCommand("autores", function()
        local current = DQ.Config:Get("automation", "autoRes", "enabled")
        local newVal = not current
        DQ.Config:Set("automation", "autoRes", "enabled", newVal)
        local statusStr = newVal and (L["STATUS_ACTIVE"] or "|cff00ff00ACTIVADA|r") or (L["STATUS_INACTIVE"] or "|cffff3333DESACTIVADA|r")
        DQ:Print((L["AUTO_RES"] or "Auto-aceptar Resurrección") .. ": " .. statusStr)
    end, "Alterna auto-aceptar resurrección en wipes.", "Toggles auto-accepting resurrection on wipes.", 90)

    -- 10. Test Alert
    DQ:RegisterCommand("test", function()
        DQ:Print(L["MSG_TESTING"] or "Probando aviso visual gigante y audio...")
        if DQ.Alert and DQ.Alert.Trigger then DQ.Alert:Trigger() end
    end, "Dispara el aviso visual gigante y el audio de alerta.", "Triggers giant visual warning banner and alert audio.", 100)

    -- 11. Death Simulation
    DQ:RegisterCommand("sim", function(arg)
        if arg == "stop" or arg == "off" or arg == "close" then
            if DQ.Detection and DQ.Detection.StopSimulation then
                DQ.Detection:StopSimulation()
            end
            return
        end
        if DQ.Detection and DQ.Detection.StartSimulation then
            DQ.Detection:StartSimulation()
        end
    end, "Simula la ventana de muerte y prueba el bloqueo (usa 'stop' para cerrar).", "Simulates death dialog and tests release prevention (use 'stop' to close).", 110)

    -- 12. Audio Test
    DQ:RegisterCommand("sound", function()
        if DQ.Config:Get("releaseGuard", "soundEnabled") == false then
            local iconOff = "|TInterface\\AddOns\\" .. addonName .. "\\sound_off:14:14:0:0|t "
            DQ:Print(iconOff .. (L["MSG_SOUND_MUTED_HINT"] or "|cffff3333El sonido de alerta está silenciado (MUTE).|r Escribe |cffffcc00/qol mute|r o usa el panel para reactivarlo."))
        else
            local iconOn = "|TInterface\\AddOns\\" .. addonName .. "\\sound_on:14:14:0:0|t "
            DQ:Print(iconOn .. (L["MSG_SOUND_PLAY"] or "Reproduciendo audio de alerta..."))
            local ok = DQ.Alert and DQ.Alert.PlaySound and DQ.Alert:PlaySound()
            if not ok then
                DQ:Print(L["MSG_SOUND_HINT"] or "|cffffcc00Aviso:|r Si el sonido no suena, escribe |cffffcc00/reload|r para que el cliente indexe el nuevo archivo de audio o revisa que el volumen del juego no esté en silencio.")
            end
        end
    end, "Prueba la reproducción del efecto de audio.", "Tests playback of the alert audio effect.", 120)

    -- 13. Status
    DQ:RegisterCommand("status", function()
        local active = DQ.Detection:ShouldProtect()
        local inInst, instType = IsInInstance()
        local statusStr = active and (L["STATUS_ACTIVE"] or "|cff00ff00ACTIVADA|r") or (L["STATUS_INACTIVE"] or "|cffff3333DESACTIVADA|r")
        local fmt = L["MSG_STATUS"] or "Estado de protección: %s (Instancia: %s, Tipo: %s)"
        DQ:Print(string.format(fmt, statusStr, tostring(inInst), tostring(instType)))

        local autoResStatus = DQ.Config:Get("automation", "autoRes", "enabled") and (L["STATUS_ACTIVE"] or "|cff00ff00ACTIVADA|r") or (L["STATUS_INACTIVE"] or "|cffff3333DESACTIVADA|r")
        DQ:Print((L["AUTO_RES"] or "Auto-aceptar Resurrección") .. ": " .. autoResStatus)

        local soundOn = DQ.Config:Get("releaseGuard", "soundEnabled") ~= false
        local soundIcon = soundOn and ("|TInterface\\AddOns\\" .. addonName .. "\\sound_on:14:14:0:0|t ") or ("|TInterface\\AddOns\\" .. addonName .. "\\sound_off:14:14:0:0|t ")
        local soundStatus = soundOn and (L["STATUS_ACTIVE"] or "|cff00ff00ACTIVADO|r") or (L["STATUS_INACTIVE"] or "|cffff3333SILENCIADO|r")
        DQ:Print((L["SOUND_ENABLED"] or "Sonido de alerta") .. ": " .. soundIcon .. soundStatus)

        if DQ.Optimizer then
            local isOpt = DQ.Optimizer:IsOptimized()
            local fpsStatusStr = isOpt and (L["FPS_STATUS_OPT"] or "|cff00ff00MÁXIMO FPS ACTIVO|r")
                                        or  (L["FPS_STATUS_NORMAL"] or "|cffaaaaaaOriginal / Estándar|r")
            local backupCount = 0
            local backup = DQ.Config:Get("fps", "backup")
            if backup and type(backup) == "table" then
                for _ in pairs(backup) do backupCount = backupCount + 1 end
            end
            local backupInfo = backupCount > 0 and string.format("|cff00ff00Sí (%d opciones)|r", backupCount) or "|cffffaa00No guardada|r"
            DQ:Print((L["SECTION_FPS_TITLE"] or "Optimización FPS") .. ": " .. fpsStatusStr .. " (Backup: " .. backupInfo .. ")")
        end
    end, "Muestra el estado actual de protección, auto-res y optimización FPS.", "Shows current status of protection, auto-res, and FPS optimization.", 130)
end

InitDefaultCommands()
