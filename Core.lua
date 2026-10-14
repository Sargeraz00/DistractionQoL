-- Core.lua
-- Main lifecycle coordinator and Slash command dispatcher for DistractionQoL
-- Fully updated for WoW 12.1.0 (Midnight)

local addonName, DQ = ...

-- Safe print helper
local function PrintMsg(msg)
    local formatted = "|cff00e5ff[DistractionQoL]|r " .. tostring(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(formatted)
    elseif print then
        print(formatted)
    end
end

-- ==========================================================
-- EVENT LIFECYCLE MANAGEMENT
-- ==========================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and (arg1 == addonName or arg1 == "DistractionQoL" or arg1 == "BaneBurroReminder") then
        if DQ.Migration and DQ.Migration.Run then
            DQ.Migration:Run()
        end
        DQ.Config:Init()
        DQ.Hook:Init()
        DQ.RaidFlow:Init()
        DQ.Automation:Init()
        DQ.Optimizer:Init()
        DQ.BagSort:Init()
        DQ.UI:RegisterSettingsCategory()
    elseif event == "PLAYER_LOGIN" then
        DQ.Hook:Init()
        if DQ.UI and DQ.UI.CheckSkinning then
            DQ.UI:CheckSkinning()
        end
        local L = DQ.L or {}
        PrintMsg(L["MSG_LOADED"] or "Addon cargado (WoW 12.1.5 Midnight). Escribe |cffffcc00/qol|r para abrir el panel.")
    end
end)

-- ==========================================================
-- SLASH COMMAND REGISTRATION
-- ==========================================================
SLASH_DISTRACTIONQOL1 = "/qol"
SLASH_DISTRACTIONQOL2 = "/dqol"
SLASH_DISTRACTIONQOL3 = "/distraction"
SLASH_DISTRACTIONQOL4 = "/burro" -- Meme command alias!

local function HandleSlashCmd(msg)
    local cmd, arg = (msg or ""):lower():match("^%s*(%S*)%s*(%S*)")
    local L = DQ.L or {}

    if cmd == "" or cmd == "config" or cmd == "panel" then
        -- Open or toggle configuration console
        DQ.UI:Toggle()

    elseif cmd == "test" then
        PrintMsg(L["MSG_TESTING"] or "Probando aviso visual gigante y audio...")
        DQ.Alert:Trigger()

    elseif cmd == "sim" then
        if arg == "stop" or arg == "off" or arg == "close" then
            if DQ.Hook and DQ.Hook.DismissSimulation then
                DQ.Hook.DismissSimulation()
            end
            return
        end
        DQ.Detection.simMode = true
        if StaticPopupDialogs then
            for _, k in ipairs({"DEATH", "DEATH_RELEASE"}) do
                local d = StaticPopupDialogs[k]
                if d then
                    d._BaneBurroHooked = nil
                    if d.selectCallbackByIndex or d.OnButton1 then
                        d.OnAccept = nil
                    end
                end
            end
        end
        DQ.Hook:Init()
        PrintMsg(L["MSG_SIM_START"] or "|cffffcc00Modo simulación activo:|r Ventana de liberación abierta.\n1. Un clic normal en 'Liberar espíritu' será bloqueado y activará la alerta.\n2. Mantén presionado SHIFT y haz clic para cerrar la ventana.")
        StaticPopup_Show("DEATH")

    elseif cmd == "check" or cmd == "buffs" or cmd == "consumables" then
        if DQ.RaidFlow then
            DQ.RaidFlow:CheckConsumables(true)
        end

    elseif cmd == "sort" or cmd == "bags" or cmd == "bolsas" then
        if DQ.BagSort then
            DQ.BagSort:SortBags()
        end

    elseif cmd == "mute" then
        local current = DQ.Config:Get("releaseGuard", "soundEnabled") ~= false
        local newVal = not current
        DQ.Config:Set("releaseGuard", "soundEnabled", newVal)
        local icon = newVal and ("|TInterface\\AddOns\\" .. addonName .. "\\sound_on:14:14:0:0|t ")
                             or  ("|TInterface\\AddOns\\" .. addonName .. "\\sound_off:14:14:0:0|t ")
        local statusMsg = newVal and (L["MSG_MUTE_OFF"] or "Sonido de alerta: |cff00ff00ACTIVADO|r") or (L["MSG_MUTE_ON"] or "Sonido de alerta: |cffff3333SILENCIADO (MUTE)|r")
        PrintMsg(icon .. statusMsg)
        if DQ.UI and DQ.UI.UpdateSoundControls then
            DQ.UI:UpdateSoundControls()
        end

    elseif cmd == "sound" then
        if DQ.Config:Get("releaseGuard", "soundEnabled") == false then
            local iconOff = "|TInterface\\AddOns\\" .. addonName .. "\\sound_off:14:14:0:0|t "
            PrintMsg(iconOff .. (L["MSG_SOUND_MUTED_HINT"] or "|cffff3333El sonido de alerta está silenciado (MUTE).|r Escribe |cffffcc00/qol mute|r o usa el panel para reactivarlo."))
        else
            local iconOn = "|TInterface\\AddOns\\" .. addonName .. "\\sound_on:14:14:0:0|t "
            PrintMsg(iconOn .. (L["MSG_SOUND_PLAY"] or "Reproduciendo audio de alerta..."))
            local ok = DQ.Alert:PlaySound()
            if not ok then
                PrintMsg(L["MSG_SOUND_HINT"] or "|cffffcc00Aviso:|r Si el sonido no suena, escribe |cffffcc00/reload|r para que el cliente indexe el nuevo archivo de audio o revisa que el volumen del juego no esté en silencio.")
            end
        end

    elseif cmd == "autores" then
        local current = DQ.Config:Get("automation", "autoRes", "enabled")
        local newVal = not current
        DQ.Config:Set("automation", "autoRes", "enabled", newVal)
        local statusStr = newVal and (L["STATUS_ACTIVE"] or "|cff00ff00ACTIVADA|r") or (L["STATUS_INACTIVE"] or "|cffff3333DESACTIVADA|r")
        PrintMsg((L["AUTO_RES"] or "Auto-aceptar Resurrección") .. ": " .. statusStr)

    elseif cmd == "fps" then
        if not DQ.Optimizer then return end
        if arg == "save" or arg == "backup" then
            DQ.Optimizer:SaveBackup()
        elseif arg == "opt" or arg == "on" or arg == "max" then
            DQ.Optimizer:ApplyOptimal()
        elseif arg == "restore" or arg == "off" or arg == "reset" then
            DQ.Optimizer:RestoreOriginal()
        else
            -- Toggle between optimal and restore
            if DQ.Optimizer:IsOptimized() then
                DQ.Optimizer:RestoreOriginal()
            else
                DQ.Optimizer:ApplyOptimal()
            end
        end

    elseif cmd == "status" then
        local active = DQ.Detection:ShouldProtect()
        local inInst, instType = IsInInstance()
        local statusStr = active and (L["STATUS_ACTIVE"] or "|cff00ff00ACTIVADA|r") or (L["STATUS_INACTIVE"] or "|cffff3333DESACTIVADA|r")
        local fmt = L["MSG_STATUS"] or "Estado de protección: %s (Instancia: %s, Tipo: %s)"
        PrintMsg(string.format(fmt, statusStr, tostring(inInst), tostring(instType)))

        local autoResStatus = DQ.Config:Get("automation", "autoRes", "enabled") and (L["STATUS_ACTIVE"] or "|cff00ff00ACTIVADA|r") or (L["STATUS_INACTIVE"] or "|cffff3333DESACTIVADA|r")
        PrintMsg((L["AUTO_RES"] or "Auto-aceptar Resurrección") .. ": " .. autoResStatus)

        local soundOn = DQ.Config:Get("releaseGuard", "soundEnabled") ~= false
        local soundIcon = soundOn and ("|TInterface\\AddOns\\" .. addonName .. "\\sound_on:14:14:0:0|t ") or ("|TInterface\\AddOns\\" .. addonName .. "\\sound_off:14:14:0:0|t ")
        local soundStatus = soundOn and (L["STATUS_ACTIVE"] or "|cff00ff00ACTIVADO|r") or (L["STATUS_INACTIVE"] or "|cffff3333SILENCIADO|r")
        PrintMsg((L["SOUND_ENABLED"] or "Sonido de alerta") .. ": " .. soundIcon .. soundStatus)

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
            PrintMsg((L["SECTION_FPS_TITLE"] or "Optimización FPS") .. ": " .. fpsStatusStr .. " (Backup: " .. backupInfo .. ")")
        end

    else
        local isSpanish = (GetLocale and (GetLocale() == "esES" or GetLocale() == "esMX"))
        if isSpanish then
            PrintMsg("--- |cff00e5ffDistractionQoL|r Comandos ---")
            PrintMsg("|cffffcc00/qol|r (o |cffffcc00/burro|r) - Abre el panel de configuración.")
            PrintMsg("|cffffcc00/qol sort|r - Ordena bolsas (inverso, materiales a bolsa de profesión).")
            PrintMsg("|cffffcc00/qol check|r - Revisa si te faltan consumibles (Comida, Frasco, Runas, Arma).")
            PrintMsg("|cffffcc00/qol fps|r - Alterna entre Máximo FPS para Raid y ajustes originales.")
            PrintMsg("|cffffcc00/qol fps save|r - Guarda la configuración gráfica actual como backup.")
            PrintMsg("|cffffcc00/qol fps restore|r - Restaura la configuración gráfica original.")
            PrintMsg("|cffffcc00/qol mute|r - Silencia o activa el sonido de alerta.")
            PrintMsg("|cffffcc00/qol autores|r - Alterna auto-aceptar resurrección.")
            PrintMsg("|cffffcc00/qol test|r - Dispara el aviso gigante y el audio de alerta.")
            PrintMsg("|cffffcc00/qol sim|r - Simula la ventana de muerte y prueba el bloqueo.")
            PrintMsg("|cffffcc00/qol sound|r - Prueba la reproducción de audio.")
            PrintMsg("|cffffcc00/qol status|r - Muestra el estado de protección, auto-res y FPS.")
        else
            PrintMsg("--- |cff00e5ffDistractionQoL|r Commands ---")
            PrintMsg("|cffffcc00/qol|r (or |cffffcc00/burro|r) - Open configuration console.")
            PrintMsg("|cffffcc00/qol sort|r - Sort bags (reverse order, reagents into reagent bag).")
            PrintMsg("|cffffcc00/qol check|r - Check missing consumables (Food, Flask, Rune, Weapon).")
            PrintMsg("|cffffcc00/qol fps|r - Toggle between Optimal Raid FPS and original settings.")
            PrintMsg("|cffffcc00/qol fps save|r - Save current graphics settings as backup.")
            PrintMsg("|cffffcc00/qol fps restore|r - Restore original graphics settings.")
            PrintMsg("|cffffcc00/qol mute|r - Mute or unmute alert sound.")
            PrintMsg("|cffffcc00/qol autores|r - Toggle auto-accept resurrection.")
            PrintMsg("|cffffcc00/qol test|r - Trigger giant warning banner and alert audio.")
            PrintMsg("|cffffcc00/qol sim|r - Simulate death dialog and test release prevention.")
            PrintMsg("|cffffcc00/qol sound|r - Test audio playback.")
            PrintMsg("|cffffcc00/qol status|r - Show current protection, auto-res & FPS status.")
        end
    end
end

SlashCmdList["DISTRACTIONQOL"] = HandleSlashCmd
SlashCmdList["BANEBURRO"] = HandleSlashCmd
SlashCmdList["BANEBURROREMINDER"] = HandleSlashCmd
SlashCmdList["BBR"] = HandleSlashCmd
