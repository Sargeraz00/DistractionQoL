-- TabPerformance.lua
-- Page 4: Performance & FPS Optimizer settings
-- Manages graphics presets, maximum raid FPS profile, settings backup/restore, and garbage collection on loading screens

local addonName, DQ = ...

DQ.UI = DQ.UI or {}

function DQ.UI:BuildTabPerformance(parentFrame, pPerf)
    local L = DQ.L or {}

    local perfTitle = pPerf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    perfTitle:SetPoint("TOPLEFT", pPerf, "TOPLEFT", 4, 0)
    perfTitle:SetText("|cff00e5ff" .. (L["SECTION_FPS_TITLE"] or "Optimización Gráfica en Raid") .. "|r")

    local statusFps = pPerf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusFps:SetPoint("TOPLEFT", perfTitle, "BOTTOMLEFT", 0, -8)
    parentFrame.statusFps = statusFps

    local statusBackup = pPerf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusBackup:SetPoint("TOPLEFT", statusFps, "BOTTOMLEFT", 0, -4)
    parentFrame.statusBackup = statusBackup

    -- Clean loading GC
    self:CreateCheckbox(pPerf, L["CLEAN_LOADING_GC"] or "Limpieza de memoria en pantallas de carga", 8, -64, DQ.Config:Get("fps", "cleanLoadingGC"), function(checked)
        DQ.Config:Set("fps", "cleanLoadingGC", checked)
    end)

    local noteFps = pPerf:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    noteFps:SetPoint("TOPLEFT", pPerf, "TOPLEFT", 8, -100)
    noteFps:SetPoint("RIGHT", pPerf, "RIGHT", -8, 0)
    noteFps:SetJustifyH("LEFT")
    noteFps:SetWordWrap(true)
    noteFps:SetText(L["FPS_NOTE"] or "|cff00e5ff* Mantiene activas las proyecciones en el suelo para ver todas las áreas de mecánicas.|r")

    -- Buttons row for FPS
    local btnFpsSave = self:CreateFlatButton(pPerf, L["BTN_FPS_SAVE"] or "Guardar Actual", 130, 26)
    btnFpsSave:SetPoint("TOPLEFT", pPerf, "TOPLEFT", 8, -145)
    btnFpsSave:SetScript("OnClick", function()
        if DQ.Optimizer then DQ.Optimizer:SaveBackup() end
        DQ.UI:UpdateFPSControls()
    end)

    local btnFpsOpt = self:CreateFlatButton(pPerf, L["BTN_FPS_OPT"] or "Optimizar FPS", 140, 26)
    btnFpsOpt:SetPoint("LEFT", btnFpsSave, "RIGHT", 10, 0)
    btnFpsOpt:SetScript("OnClick", function()
        if DQ.Optimizer then DQ.Optimizer:ApplyOptimal() end
    end)

    local btnFpsRestore = self:CreateFlatButton(pPerf, L["BTN_FPS_RESTORE"] or "Restaurar", 130, 26)
    btnFpsRestore:SetPoint("LEFT", btnFpsOpt, "RIGHT", 10, 0)
    btnFpsRestore:SetScript("OnClick", function()
        if DQ.Optimizer then DQ.Optimizer:RestoreOriginal() end
    end)
end
