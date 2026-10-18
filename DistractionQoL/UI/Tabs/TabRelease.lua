-- TabRelease.lua
-- Page 1: Spirit Release Protection (Anti-Burro) settings
-- Manages dungeon/raid filters, sound choice presets, and M+ full wipe release

local addonName, DQ = ...

DQ.UI = DQ.UI or {}

function DQ.UI:BuildTabRelease(parentFrame, pRelease)
    local L = DQ.L or {}

    local relTitle = pRelease:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    relTitle:SetPoint("TOPLEFT", pRelease, "TOPLEFT", 4, 0)
    relTitle:SetText("|cff00e5ff" .. (L["SECTION_RELEASE_TITLE"] or "Protección Anti-Liberar") .. "|r")

    local relDesc = pRelease:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    relDesc:SetPoint("TOPLEFT", relTitle, "BOTTOMLEFT", 0, -4)
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

    local soundStatusIcon = pRelease:CreateTexture(nil, "ARTWORK")
    soundStatusIcon:SetSize(16, 16)
    soundStatusIcon:SetPoint("LEFT", cbSound.text, "RIGHT", 6, 0)
    soundStatusIcon:SetTexture(self:ResolveSoundPath(DQ.Config:Get("releaseGuard", "soundEnabled") ~= false))
    parentFrame.soundStatusIcon = soundStatusIcon

    -- Sound Presets Selector
    local lblSoundChoice = pRelease:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lblSoundChoice:SetPoint("TOPLEFT", pRelease, "TOPLEFT", 10, -244)
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
                    b:SetBackdropColor(0.0, 0.50, 0.65, 0.95)
                    b:SetBackdropBorderColor(0.0, 0.90, 1.0, 1)
                    if b.text then b.text:SetTextColor(1, 1, 1, 1) end
                else
                    b:SetBackdropColor(0.10, 0.10, 0.14, 0.95)
                    b:SetBackdropBorderColor(0.20, 0.20, 0.25, 1)
                    if b.text then b.text:SetTextColor(0.70, 0.70, 0.75, 1) end
                end
            end
        end
    end

    for i, opt in ipairs(soundOptions) do
        local btnOpt = self:CreateFlatButton(pRelease, opt.label, 80, 20)
        btnOpt:SetPoint("TOPLEFT", pRelease, "TOPLEFT", 105 + (i - 1) * 85, -242)
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
    self:CreateCheckbox(pRelease, L["OPT_WIPE_AUTO_RELEASE"] or "M+ Wipe Total: Auto-liberar espíritu si muere todo el grupo", 8, -276, DQ.Config:Get("mythicPlus", "autoReleaseOnWipe"), function(checked)
        DQ.Config:Set("mythicPlus", "autoReleaseOnWipe", checked)
    end)
    local wipeDesc = pRelease:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    wipeDesc:SetPoint("TOPLEFT", pRelease, "TOPLEFT", 32, -302)
    wipeDesc:SetPoint("RIGHT", pRelease, "RIGHT", -12, 0)
    wipeDesc:SetJustifyH("LEFT")
    wipeDesc:SetText(L["OPT_WIPE_AUTO_RELEASE_DESC"] or "|cff888888Desactiva la protección y libera al morir los 5 jugadores para ahorrar tiempo de piedra.|r")
end
