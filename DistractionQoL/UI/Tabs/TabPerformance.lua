-- TabPerformance.lua
-- Page 4: Performance & FPS Optimizer settings
-- Manages graphics presets, maximum raid FPS profile, settings backup/restore, and garbage collection on loading screens

local addonName, DQ = ...

DQ.UI = DQ.UI or {}

function DQ.UI:BuildTabPerformance(parentFrame, pPerf)
    local L = DQ.L or {}
    local m3 = (DQ.Theme and DQ.Theme.M3) or {}

    local perfTitle = pPerf:CreateFontString(nil, "OVERLAY")
    perfTitle:SetPoint("TOPLEFT", pPerf, "TOPLEFT", 6, 0)
    DQ.Theme.ApplyText(perfTitle, 14, "bold", m3.primary)
    perfTitle:SetText(L["SECTION_FPS_TITLE"] or "Optimización Gráfica en Raid")

    local statusFps = pPerf:CreateFontString(nil, "OVERLAY")
    statusFps:SetPoint("TOPLEFT", perfTitle, "BOTTOMLEFT", 0, -8)
    DQ.Theme.ApplyText(statusFps, 11, "semibold", m3.onSurface)
    parentFrame.statusFps = statusFps

    local statusBackup = pPerf:CreateFontString(nil, "OVERLAY")
    statusBackup:SetPoint("TOPLEFT", statusFps, "BOTTOMLEFT", 0, -4)
    DQ.Theme.ApplyText(statusBackup, 11, "regular", m3.onSurfaceVariant)
    parentFrame.statusBackup = statusBackup

    -- Clean loading GC
    self:CreateCheckbox(pPerf, L["CLEAN_LOADING_GC"] or "Limpieza de memoria en pantallas de carga", 8, -64, DQ.Config:Get("fps", "cleanLoadingGC"), function(checked)
        DQ.Config:Set("fps", "cleanLoadingGC", checked)
    end)

    local noteFps = pPerf:CreateFontString(nil, "OVERLAY")
    noteFps:SetPoint("TOPLEFT", pPerf, "TOPLEFT", 8, -100)
    noteFps:SetPoint("RIGHT", pPerf, "RIGHT", -8, 0)
    noteFps:SetJustifyH("LEFT")
    noteFps:SetWordWrap(true)
    DQ.Theme.ApplyText(noteFps, 11, "regular", m3.onSurfaceVariant)
    noteFps:SetText(L["FPS_NOTE"] or "* Mantiene activas las proyecciones en el suelo para ver todas las áreas de mecánicas.")

    -- Buttons row for FPS (M3 buttons)
    local btnFpsSave = self:CreateM3Button(pPerf, L["BTN_FPS_SAVE"] or "Guardar Actual", "tonal", 130, 28)
    btnFpsSave:SetPoint("TOPLEFT", pPerf, "TOPLEFT", 8, -145)
    btnFpsSave:SetScript("OnClick", function()
        if DQ.Optimizer then DQ.Optimizer:SaveBackup() end
        DQ.UI:UpdateFPSControls()
    end)

    local btnFpsOpt = self:CreateM3Button(pPerf, L["BTN_FPS_OPT"] or "Optimizar FPS", "filled", 140, 28)
    btnFpsOpt:SetPoint("LEFT", btnFpsSave, "RIGHT", 10, 0)
    btnFpsOpt:SetScript("OnClick", function()
        if DQ.Optimizer then DQ.Optimizer:ApplyOptimal() end
    end)

    local btnFpsRestore = self:CreateM3Button(pPerf, L["BTN_FPS_RESTORE"] or "Restaurar", "outlined", 120, 28)
    btnFpsRestore:SetPoint("LEFT", btnFpsOpt, "RIGHT", 10, 0)
    btnFpsRestore:SetScript("OnClick", function()
        if DQ.Optimizer then DQ.Optimizer:RestoreOriginal() end
    end)
end
