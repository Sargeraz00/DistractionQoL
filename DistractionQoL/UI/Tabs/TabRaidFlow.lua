-- TabRaidFlow.lua
-- Page 2: Raid Flow & Readiness settings
-- Manages taskbar flashing, ready check sound, consumables warnings, LFG alerts, and targeted-by tooltips

local addonName, DQ = ...

DQ.UI = DQ.UI or {}

function DQ.UI:BuildTabRaidFlow(parentFrame, pFlow)
    local L = DQ.L or {}
    local m3 = (DQ.Theme and DQ.Theme.M3) or {}

    local flowTitle = pFlow:CreateFontString(nil, "OVERLAY")
    flowTitle:SetPoint("TOPLEFT", pFlow, "TOPLEFT", 6, 0)
    DQ.Theme.ApplyText(flowTitle, 14, "bold", m3.primary)
    flowTitle:SetText(L["SECTION_RAIDFLOW_TITLE"] or "Flujo de Banda & Preparación")

    local flowDesc = pFlow:CreateFontString(nil, "OVERLAY")
    flowDesc:SetPoint("TOPLEFT", flowTitle, "BOTTOMLEFT", 0, -3)
    DQ.Theme.ApplyText(flowDesc, 11, "regular", m3.onSurfaceVariant)
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
    local btnCheckNow = self:CreateM3Button(pFlow, L["OPT_BTN_CHECK_CONSUMABLES"] or "Revisar Consumibles Ahora", "tonal", 220, 26)
    btnCheckNow:SetPoint("TOPLEFT", pFlow, "TOPLEFT", 8, -214)
    btnCheckNow:SetScript("OnClick", function()
        if DQ.RaidFlow then DQ.RaidFlow:CheckConsumables(true) end
    end)

    -- Checkbox: Tooltip Targeted By
    self:CreateCheckbox(pFlow, L["OPT_TOOLTIP_TARGETED_BY"] or "Tooltip de Mob: Mostrar qué miembros lo están enfocando (Targeted By)", 8, -256, DQ.Config:Get("tooltip", "targetedBy"), function(checked)
        DQ.Config:Set("tooltip", "targetedBy", checked)
    end)
    local ttDesc = pFlow:CreateFontString(nil, "OVERLAY")
    ttDesc:SetPoint("TOPLEFT", pFlow, "TOPLEFT", 32, -282)
    ttDesc:SetPoint("RIGHT", pFlow, "RIGHT", -12, 0)
    ttDesc:SetJustifyH("LEFT")
    ttDesc:SetWordWrap(true)
    DQ.Theme.ApplyText(ttDesc, 11, "regular", m3.onSurfaceVariant)
    ttDesc:SetText(L["OPT_TOOLTIP_TARGETED_BY_DESC"] or "Agrega al tooltip del objetivo la cantidad y rol de jugadores que lo tienen en target (ej: 1T 1H 2D).")
end
