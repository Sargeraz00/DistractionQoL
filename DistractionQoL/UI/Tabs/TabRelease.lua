-- TabRelease.lua
-- Page 1: Spirit Release Protection (Anti-Burro) settings
-- Manages dungeon/raid filters, sound choice presets, and M+ full wipe release

local addonName, DQ = ...

DQ.UI = DQ.UI or {}

function DQ.UI:BuildTabRelease(parentFrame, pRelease)
    local L = DQ.L or {}
    local m3 = (DQ.Theme and DQ.Theme.M3) or {}

    local relTitle = pRelease:CreateFontString(nil, "OVERLAY")
    relTitle:SetPoint("TOPLEFT", pRelease, "TOPLEFT", 6, 0)
    DQ.Theme.ApplyText(relTitle, 14, "bold", m3.primary)
    relTitle:SetText(L["SECTION_RELEASE_TITLE"] or "Protección Anti-Liberar")

    local relDesc = pRelease:CreateFontString(nil, "OVERLAY")
    relDesc:SetPoint("TOPLEFT", relTitle, "BOTTOMLEFT", 0, -3)
    DQ.Theme.ApplyText(relDesc, 11, "regular", m3.onSurfaceVariant)
    relDesc:SetText(L["SECTION_RELEASE_DESC"] or "Evita liberar espíritu por accidente en combate. Mantén SHIFT para liberar.")

    -- Checkbox: Dungeons
    self:CreateCheckbox(pRelease, L["DUNGEONS"] or "Mazmorras (M+ / Heroicas)", 8, -46, DQ.Config:Get("releaseGuard", "dungeons"), function(checked)
        DQ.Config:Set("releaseGuard", "dungeons", checked)
    end)

    -- Checkbox: Raids (Master)
    local cbRaidsNormal, cbRaidsHeroic, cbRaidsMythic
    local function UpdateRaidSubs(enabled)
        if cbRaidsNormal then
            cbRaidsNormal:SetEnabled(enabled)
            cbRaidsNormal.text:SetTextColor(enabled and 1 or 0.45, enabled and 1 or 0.45, enabled and 1 or 0.45)
        end
        if cbRaidsHeroic then
            cbRaidsHeroic:SetEnabled(enabled)
            cbRaidsHeroic.text:SetTextColor(enabled and 1 or 0.45, enabled and 1 or 0.45, enabled and 1 or 0.45)
        end
        if cbRaidsMythic then
            cbRaidsMythic:SetEnabled(enabled)
            cbRaidsMythic.text:SetTextColor(enabled and 1 or 0.45, enabled and 1 or 0.45, enabled and 1 or 0.45)
        end
    end

    self:CreateCheckbox(pRelease, L["RAIDS"] or "Bandas (Raid)", 8, -74, DQ.Config:Get("releaseGuard", "raids", "enabled"), function(checked)
        DQ.Config:Set("releaseGuard", "raids", "enabled", checked)
        UpdateRaidSubs(checked)
    end)

    cbRaidsNormal = self:CreateCheckbox(pRelease, L["NORMAL"] or "Normal", 32, -100, DQ.Config:Get("releaseGuard", "raids", "normal"), function(checked)
        DQ.Config:Set("releaseGuard", "raids", "normal", checked)
    end)

    cbRaidsHeroic = self:CreateCheckbox(pRelease, L["HEROIC"] or "Heroico", 32, -126, DQ.Config:Get("releaseGuard", "raids", "heroic"), function(checked)
        DQ.Config:Set("releaseGuard", "raids", "heroic", checked)
    end)

    cbRaidsMythic = self:CreateCheckbox(pRelease, L["MYTHIC"] or "Mítico", 32, -152, DQ.Config:Get("releaseGuard", "raids", "mythic"), function(checked)
        DQ.Config:Set("releaseGuard", "raids", "mythic", checked)
    end)

    UpdateRaidSubs(DQ.Config:Get("releaseGuard", "raids", "enabled"))

    -- Checkbox: Open World
    self:CreateCheckbox(pRelease, L["OPEN_WORLD"] or "Mundo Abierto", 8, -182, DQ.Config:Get("releaseGuard", "openWorld"), function(checked)
        DQ.Config:Set("releaseGuard", "openWorld", checked)
    end)

    -- Checkbox: Sound Enabled with dynamic sound icon indicator
    local cbSound = self:CreateCheckbox(pRelease, L["SOUND_ENABLED"] or "Sonido de Alerta de Liberación", 8, -214, DQ.Config:Get("releaseGuard", "soundEnabled"), function(checked)
        DQ.Config:Set("releaseGuard", "soundEnabled", checked)
        DQ.UI:UpdateSoundControls()
    end)
    parentFrame.cbSound = cbSound

    -- Sound indicator icon placed directly adjacent to the checkbox box
    local soundStatusIcon = pRelease:CreateTexture(nil, "ARTWORK")
    soundStatusIcon:SetSize(16, 16)
    soundStatusIcon:SetPoint("LEFT", cbSound, "RIGHT", 6, 0)
    soundStatusIcon:SetTexture(self:ResolveSoundPath(DQ.Config:Get("releaseGuard", "soundEnabled") ~= false))
    parentFrame.soundStatusIcon = soundStatusIcon

    if cbSound.text then
        cbSound.text:ClearAllPoints()
        cbSound.text:SetPoint("LEFT", soundStatusIcon, "RIGHT", 6, 0)
    end

    -- Sound Presets Selector (dedicated label row to avoid any text cutoff in any language)
    local lblSoundChoice = pRelease:CreateFontString(nil, "OVERLAY")
    lblSoundChoice:SetPoint("TOPLEFT", pRelease, "TOPLEFT", 8, -246)
    DQ.Theme.ApplyText(lblSoundChoice, 12, "semibold", m3.onSurface)
    lblSoundChoice:SetText(L["OPT_AUDIO_CHOICE_LABEL"] or "Efecto de Audio:")

    local soundButtons = {}
    local soundOptions = {
        { key = "auto", label = "Auto", tooltip = L["SOUND_OPT_AUTO_TIP"] or "Easter Egg si estás en Distraction (Quel'Thalas), alarma táctica limpia para todos los demás." },
        { key = "raid_warning", label = "Raid Alert", tooltip = L["SOUND_OPT_RW_TIP"] or "Alarma clásica limpia de Raid Warning de Blizzard." },
        { key = "alarm", label = "Alarm", tooltip = L["SOUND_OPT_ALARM_TIP"] or "Tono digital táctico." },
        { key = "bane", label = "Bane Meme", tooltip = L["SOUND_OPT_BANE_TIP"] or "Audio cómico clásico: ¡Burro, sonso, no liberes!" },
    }

    local function RefreshSoundButtons()
        local current = DQ.Config:Get("releaseGuard", "soundChoice") or "auto"
        for _, opt in ipairs(soundOptions) do
            local b = soundButtons[opt.key]
            if b then
                if opt.key == current then
                    b:SetBackdropColor(unpack(m3.primaryContainer or { 0.0, 0.28, 0.32, 0.95 }))
                    b:SetBackdropBorderColor(unpack(m3.primary or { 0.0, 0.90, 1.0, 1 }))
                    if b.text then b.text:SetTextColor(1, 1, 1, 1) end
                else
                    b:SetBackdropColor(unpack(m3.surfaceContainerHigh or { 0.22, 0.28, 0.31, 0.95 }))
                    b:SetBackdropBorderColor(unpack(m3.outline or { 0.31, 0.36, 0.38, 0.55 }))
                    if b.text then b.text:SetTextColor(unpack(m3.onSurfaceVariant or { 0.65, 0.70, 0.74, 1.0 })) end
                end
            end
        end
    end

    -- Dedicated preset buttons row directly below the label
    for i, opt in ipairs(soundOptions) do
        local btnOpt = self:CreateFlatButton(pRelease, opt.label, 95, 24)
        btnOpt:SetPoint("TOPLEFT", pRelease, "TOPLEFT", 8 + (i - 1) * 105, -270)
        btnOpt:SetScript("OnClick", function()
            DQ.Config:Set("releaseGuard", "soundChoice", opt.key)
            RefreshSoundButtons()
            if DQ.Alert and DQ.Alert.PlaySound then
                DQ.Alert:PlaySound(opt.key)
            end
        end)
        soundButtons[opt.key] = btnOpt
    end
    parentFrame.RefreshSoundButtons = RefreshSoundButtons
    RefreshSoundButtons()

    -- Checkbox: Auto Release on Full Wipe in M+
    self:CreateCheckbox(pRelease, L["OPT_WIPE_AUTO_RELEASE"] or "M+ Wipe Total: Auto-liberar espíritu si muere todo el grupo", 8, -312, DQ.Config:Get("mythicPlus", "autoReleaseOnWipe"), function(checked)
        DQ.Config:Set("mythicPlus", "autoReleaseOnWipe", checked)
    end)
    local wipeDesc = pRelease:CreateFontString(nil, "OVERLAY")
    wipeDesc:SetPoint("TOPLEFT", pRelease, "TOPLEFT", 30, -336)
    wipeDesc:SetPoint("RIGHT", pRelease, "RIGHT", -12, 0)
    wipeDesc:SetJustifyH("LEFT")
    wipeDesc:SetWordWrap(true)
    DQ.Theme.ApplyText(wipeDesc, 11, "regular", m3.onSurfaceVariant)
    wipeDesc:SetText(L["OPT_WIPE_AUTO_RELEASE_DESC"] or "Desactiva la protección y libera al morir los 5 jugadores para ahorrar tiempo de piedra.")
end
