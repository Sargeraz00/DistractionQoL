-- TabRaidFlow.lua
-- Page 2: Raid Flow & Readiness settings
-- Manages taskbar flashing, ready check sound, consumables warnings, LFG alerts, and targeted-by tooltips

local addonName, DQ = ...

DQ.UI = DQ.UI or {}

function DQ.UI:BuildTabRaidFlow(parentFrame, pFlow)
    local L = DQ.L or {}

    local flowTitle = pFlow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    flowTitle:SetPoint("TOPLEFT", pFlow, "TOPLEFT", 4, 0)
    flowTitle:SetText("|cff00e5ff" .. (L["SECTION_RAIDFLOW_TITLE"] or "Flujo de Banda & Preparación") .. "|r")

    local flowDesc = pFlow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    flowDesc:SetPoint("TOPLEFT", flowTitle, "BOTTOMLEFT", 0, -4)
    flowDesc:SetText(L["SECTION_RAIDFLOW_DESC"] or "Herramientas dirigidas por eventos para no perder llamadas mientras estás distraído.")

    -- Checkbox: Flash Taskbar
    self:CreateCheckbox(pFlow, L["FLASH_TASKBAR"] or "Parpadear ventana en barra de tareas en Ready Check / Pull", 8, -46, DQ.Config:Get("raidFlow", "flashTaskbar"), function(checked)
        DQ.Config:Set("raidFlow", "flashTaskbar", checked)
    end)

    -- Checkbox: Ready Check Sound
    self:CreateCheckbox(pFlow, L["READY_CHECK_SOUND"] or "Alerta sonora por canal Master en Ready Check", 8, -78, DQ.Config:Get("raidFlow", "readyCheckSound"), function(checked)
        DQ.Config:Set("raidFlow", "readyCheckSound", checked)
    end)

    -- Checkbox: Check Consumables at Ready Check
    self:CreateCheckbox(pFlow, L["CHECK_CONSUMABLES"] or "Avisar si faltan consumibles en Ready Check", 8, -110, DQ.Config:Get("raidFlow", "checkConsumables"), function(checked)
        DQ.Config:Set("raidFlow", "checkConsumables", checked)
    end)

    -- Checkbox: Warn Expiring Consumables (< 5 min)
    self:CreateCheckbox(pFlow, L["OPT_EXPIRING_CONSUMABLES"] or "Avisar en chat si consumibles expiran en < 5 min fuera de combate", 8, -142, DQ.Config:Get("raidFlow", "warnExpiringConsumables"), function(checked)
        DQ.Config:Set("raidFlow", "warnExpiringConsumables", checked)
    end)

    -- Checkbox: LFG Queue Proposal Alert
    self:CreateCheckbox(pFlow, L["OPT_LFG_ALERT"] or "Parpadear barra de tareas y alerta sonora en llamada de buscador (LFG)", 8, -174, DQ.Config:Get("raidFlow", "lfgAlert"), function(checked)
        DQ.Config:Set("raidFlow", "lfgAlert", checked)
    end)

    -- Manual Consumables Check button
    local btnCheckNow = self:CreateFlatButton(pFlow, L["OPT_BTN_CHECK_CONSUMABLES"] or "Revisar Consumibles Ahora", 200, 24)
    btnCheckNow:SetPoint("TOPLEFT", pFlow, "TOPLEFT", 8, -214)
    btnCheckNow:SetScript("OnClick", function()
        if DQ.RaidFlow then DQ.RaidFlow:CheckConsumables(true) end
    end)

    -- Checkbox: Tooltip Targeted By
    self:CreateCheckbox(pFlow, L["OPT_TOOLTIP_TARGETED_BY"] or "Tooltip de Mob: Mostrar qué miembros lo están enfocando (Targeted By)", 8, -256, DQ.Config:Get("tooltip", "targetedBy"), function(checked)
        DQ.Config:Set("tooltip", "targetedBy", checked)
    end)
    local ttDesc = pFlow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ttDesc:SetPoint("TOPLEFT", pFlow, "TOPLEFT", 32, -282)
    ttDesc:SetPoint("RIGHT", pFlow, "RIGHT", -12, 0)
    ttDesc:SetJustifyH("LEFT")
    ttDesc:SetText(L["OPT_TOOLTIP_TARGETED_BY_DESC"] or "|cff888888Agrega al tooltip del objetivo la cantidad y rol de jugadores que lo tienen en target (ej: 1T 1H 2D).|r")

    -- ==========================================================
    -- LFG COMPOSITION RADAR
    -- ==========================================================
    local secRadar = pFlow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    secRadar:SetPoint("TOPLEFT", pFlow, "TOPLEFT", 8, -315)
    secRadar:SetText("|cff00e5ff" .. (L["LFG_RADAR_TITLE"] or "Radar de Composición en Buscador (LFG)") .. "|r")

    local cbRadarEntries, cbRadarRec

    local function UpdateRadarSubStates(enabled)
        local alpha = enabled and 1 or 0.45
        for _, cb in ipairs({cbRadarEntries, cbRadarRec}) do
            if cb then
                cb:SetEnabled(enabled)
                if cb.text then cb.text:SetTextColor(alpha, alpha, alpha) end
            end
        end
    end

    local isRadarEnabled = DQ.Config:Get("lfgRadar", "enabled") ~= false

    self:CreateCheckbox(pFlow, L["LFG_RADAR_ENABLE"] or "Activar Radar de Composición (analiza utilidades en grupos)", 8, -338, isRadarEnabled, function(checked)
        DQ.Config:Set("lfgRadar", "enabled", checked)
        UpdateRadarSubStates(checked)
    end)

    cbRadarEntries = self:CreateCheckbox(pFlow, L["LFG_RADAR_BADGES"] or "Mostrar insignias [BL] [CR] directamente en las filas de búsqueda", 28, -362, DQ.Config:Get("lfgRadar", "showEntryBadges"), function(checked)
        DQ.Config:Set("lfgRadar", "showEntryBadges", checked)
    end)

    cbRadarRec = self:CreateCheckbox(pFlow, L["LFG_RADAR_RECOMMEND"] or "Resaltar grupos recomendados donde tu clase aporta lo que falta", 28, -386, DQ.Config:Get("lfgRadar", "highlightRecommended"), function(checked)
        DQ.Config:Set("lfgRadar", "highlightRecommended", checked)
    end)

    UpdateRadarSubStates(isRadarEnabled)
end
