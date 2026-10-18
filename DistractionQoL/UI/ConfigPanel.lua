-- UI.lua
-- Settings console with modern flat obsidian styling and tabbed navigation
-- Fully compatible with EllesmereUI (Official Skinning API) and ElvUI (Skins Module)
-- Fully localized and integrated with WoW 12.1.0 Settings API

local addonName, DQ = ...

DQ.UI = {}

local configFrame = nil

-- Helper to dynamically resolve sound icon texture path regardless of folder name
local resolvedSoundDir = nil
local function ResolveSoundPath(isOn)
    local file = isOn and "sound_on" or "sound_off"
    if not resolvedSoundDir then
        local testTex = UIParent:CreateTexture()
        if testTex:SetTexture("Interface\\AddOns\\" .. addonName .. "\\" .. file) then
            resolvedSoundDir = "Interface\\AddOns\\" .. addonName .. "\\"
        elseif testTex:SetTexture("Interface\\AddOns\\DistractionQoL\\" .. file) then
            resolvedSoundDir = "Interface\\AddOns\\DistractionQoL\\"
        else
            resolvedSoundDir = "Interface\\AddOns\\" .. addonName .. "\\"
        end
    end
    return resolvedSoundDir .. file
end

local function GetSoundIcon(isOn, size)
    size = size or 14
    local path = ResolveSoundPath(isOn)
    return string.format("|T%s:%d:%d:0:0|t ", path, size, size)
end

-- Helper to create CheckButtons using standard WoW template with clean positioning
local function CreateCheckbox(parent, label, x, y, initialChecked, onClick)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetSize(22, 22)
    cb:SetChecked(initialChecked and true or false)

    local text = cb.text or (cb:GetName() and _G[cb:GetName() .. "Text"])
    if not text then
        text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        cb.text = text
    end
    text:SetText(label)

    cb:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        if onClick then
            onClick(isChecked)
        end
    end)

    return cb
end

-- Helper to create modern flat dark buttons
local function CreateFlatButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    btn:SetBackdropColor(0.12, 0.12, 0.16, 0.95)
    btn:SetBackdropBorderColor(0.24, 0.24, 0.30, 1)

    local fontString = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fontString:SetPoint("CENTER")
    fontString:SetText(text)
    btn.text = fontString

    function btn:SetButtonText(txt)
        if self.SetText then self:SetText(txt) end
        if self.text then self.text:SetText(txt) end
    end

    btn:SetScript("OnEnter", function(self)
        if not self.isSkinned then
            self:SetBackdropColor(0.18, 0.18, 0.24, 1)
            self:SetBackdropBorderColor(0.0, 0.85, 0.95, 1)
            if self.text then self.text:SetTextColor(1, 1, 1, 1) end
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if not self.isSkinned then
            self:SetBackdropColor(0.12, 0.12, 0.16, 0.95)
            self:SetBackdropBorderColor(0.24, 0.24, 0.30, 1)
            if self.text then self.text:SetTextColor(0.9, 0.9, 0.9, 1) end
        end
    end)

    return btn
end

-- Builds the configuration panel frame with tabbed navigation
function DQ.UI:CreatePanel()
    if configFrame then return configFrame end

    local L = DQ.L or {}

    -- Main Frame with modern flat obsidian backdrop
    local f = CreateFrame("Frame", "DistractionQoLConfigFrame", UIParent, "BackdropTemplate")
    f:SetSize(480, 520)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    -- Modern flat dark backdrop
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    f:SetBackdropColor(0.06, 0.06, 0.08, 0.96)
    f:SetBackdropBorderColor(0.22, 0.22, 0.26, 1)

    -- Header background bar (26px high)
    local headerBar = f:CreateTexture(nil, "BACKGROUND", nil, -5)
    headerBar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    headerBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    headerBar:SetHeight(26)
    headerBar:SetColorTexture(0, 0, 0, 0.50)
    f.headerBar = headerBar

    -- Top accent bar (Cyan aesthetic strip)
    local topBar = f:CreateTexture(nil, "ARTWORK")
    topBar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    topBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    topBar:SetHeight(2)
    topBar:SetColorTexture(0.0, 0.85, 0.95, 1)
    f.topAccent = topBar

    -- Top title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", f, "TOPLEFT", 14, -13)
    title:SetText((L["CONFIG_TITLE"] or "|cff00e5ffDistractionQoL|r") .. " |cff888888v2.1.0|r")
    f.title = title
    f.TitleText = title

    -- ==========================================================
    -- TOP-RIGHT CLOSE BUTTON & WIZARD SHORTCUT
    -- ==========================================================
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -3)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Reliable ASCII 'X' label that renders on every font without missing glyphs
    local xText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    xText:SetPoint("CENTER", 0, 0)
    xText:SetText("|cffaaaaaaX|r")
    closeBtn.xText = xText

    -- Quick Setup Wizard Button in Header
    local btnWizard = CreateFrame("Button", nil, f, "BackdropTemplate")
    btnWizard:SetSize(80, 18)
    btnWizard:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)
    btnWizard:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    btnWizard:SetBackdropColor(0.0, 0.40, 0.55, 0.90)
    btnWizard:SetBackdropBorderColor(0.0, 0.85, 1.0, 0.90)
    local bwText = btnWizard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bwText:SetPoint("CENTER")
    bwText:SetText("Asistente")
    btnWizard.text = bwText
    btnWizard:SetScript("OnClick", function()
        f:Hide()
        if DQ.Wizard then DQ.Wizard:Open() end
    end)

    closeBtn:HookScript("OnEnter", function(self)
        if not self.isSkinned and self.xText then self.xText:SetText("|cffff3333X|r") end
    end)
    closeBtn:HookScript("OnLeave", function(self)
        if not self.isSkinned and self.xText then self.xText:SetText("|cffaaaaaaX|r") end
    end)

    f.CloseButton = closeBtn
    f.Close = closeBtn

    -- ==========================================================
    -- NAVIGATION TABS
    -- ==========================================================
    local tabDefs = {
        { id = "release", label = L["TAB_RELEASE"] or "Liberación" },
        { id = "raidflow", label = L["TAB_RAIDFLOW"] or "Flujo Raid" },
        { id = "automation", label = L["TAB_AUTOMATION"] or "Automatizaciones" },
        { id = "performance", label = L["TAB_PERFORMANCE"] or "Rendimiento" },
        { id = "conflicts", label = L["TAB_CONFLICTS"] or "Compatibilidad" },
    }

    local tabButtons = {}
    local tabPages = {}
    local activeTab = "release"

    local function ShowTab(tabId)
        activeTab = tabId
        for _, def in ipairs(tabDefs) do
            local page = tabPages[def.id]
            local btn = tabButtons[def.id]
            if def.id == tabId then
                if page then page:Show() end
                if btn and not btn.isSkinned then
                    btn:SetBackdropColor(0.0, 0.45, 0.55, 0.8)
                    btn:SetBackdropBorderColor(0.0, 0.85, 0.95, 1)
                    if btn.text then btn.text:SetTextColor(1, 1, 1, 1) end
                end
            else
                if page then page:Hide() end
                if btn and not btn.isSkinned then
                    btn:SetBackdropColor(0.10, 0.10, 0.14, 0.95)
                    btn:SetBackdropBorderColor(0.20, 0.20, 0.24, 1)
                    if btn.text then btn.text:SetTextColor(0.75, 0.75, 0.75, 1) end
                end
            end
        end
    end

    local tabWidth = 86
    local tabHeight = 24
    local tabStartX = 14
    local tabY = -34

    for i, def in ipairs(tabDefs) do
        local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
        btn:SetSize(tabWidth, tabHeight)
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", tabStartX + (i - 1) * (tabWidth + 4), tabY)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        btn:SetBackdropColor(0.10, 0.10, 0.14, 0.95)
        btn:SetBackdropBorderColor(0.20, 0.20, 0.24, 1)

        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btnText:SetPoint("CENTER")
        btnText:SetText(def.label)
        btn.text = btnText

        btn:SetScript("OnClick", function()
            ShowTab(def.id)
        end)

        tabButtons[def.id] = btn

        -- Container page for this tab
        local page = CreateFrame("Frame", nil, f)
        page:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -68)
        page:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 52)
        tabPages[def.id] = page
    end

    -- ==========================================================
    -- PAGE 1: RELEASE GUARD (Anti-Burro)
    -- ==========================================================
    local pRelease = tabPages["release"]

    local relTitle = pRelease:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    relTitle:SetPoint("TOPLEFT", pRelease, "TOPLEFT", 4, 0)
    relTitle:SetText("|cff00e5ff" .. (L["SECTION_RELEASE_TITLE"] or "Protección Anti-Liberar") .. "|r")

    local relDesc = pRelease:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    relDesc:SetPoint("TOPLEFT", relTitle, "BOTTOMLEFT", 0, -4)
    relDesc:SetText(L["SECTION_RELEASE_DESC"] or "Evita liberar espíritu por accidente en combate. Mantén SHIFT para liberar.")

    -- Checkbox: Dungeons
    CreateCheckbox(pRelease, L["DUNGEONS"] or "Mazmorras (M+ / Heroicas)", 8, -46, DQ.Config:Get("releaseGuard", "dungeons"), function(checked)
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

    CreateCheckbox(pRelease, L["RAIDS"] or "Bandas (Raid)", 8, -74, DQ.Config:Get("releaseGuard", "raids", "enabled"), function(checked)
        DQ.Config:Set("releaseGuard", "raids", "enabled", checked)
        UpdateRaidSubs(checked)
    end)

    cbRaidsNormal = CreateCheckbox(pRelease, L["NORMAL"] or "Normal", 32, -100, DQ.Config:Get("releaseGuard", "raids", "normal"), function(checked)
        DQ.Config:Set("releaseGuard", "raids", "normal", checked)
    end)

    cbRaidsHeroic = CreateCheckbox(pRelease, L["HEROIC"] or "Heroico", 32, -126, DQ.Config:Get("releaseGuard", "raids", "heroic"), function(checked)
        DQ.Config:Set("releaseGuard", "raids", "heroic", checked)
    end)

    cbRaidsMythic = CreateCheckbox(pRelease, L["MYTHIC"] or "Mítico", 32, -152, DQ.Config:Get("releaseGuard", "raids", "mythic"), function(checked)
        DQ.Config:Set("releaseGuard", "raids", "mythic", checked)
    end)

    UpdateRaidSubs(DQ.Config:Get("releaseGuard", "raids", "enabled"))

    -- Checkbox: Open World
    CreateCheckbox(pRelease, L["OPEN_WORLD"] or "Mundo Abierto", 8, -182, DQ.Config:Get("releaseGuard", "openWorld"), function(checked)
        DQ.Config:Set("releaseGuard", "openWorld", checked)
    end)

    -- Checkbox: Sound Enabled with dynamic sound icon indicator
    local cbSound = CreateCheckbox(pRelease, L["SOUND_ENABLED"] or "Sonido de Alerta de Liberación (Bane.ogg)", 8, -214, DQ.Config:Get("releaseGuard", "soundEnabled"), function(checked)
        DQ.Config:Set("releaseGuard", "soundEnabled", checked)
        DQ.UI:UpdateSoundControls()
    end)
    f.cbSound = cbSound

    local soundStatusIcon = pRelease:CreateTexture(nil, "ARTWORK")
    soundStatusIcon:SetSize(16, 16)
    soundStatusIcon:SetPoint("LEFT", cbSound.text, "RIGHT", 6, 0)
    soundStatusIcon:SetTexture(ResolveSoundPath(DQ.Config:Get("releaseGuard", "soundEnabled") ~= false))
    f.soundStatusIcon = soundStatusIcon

    -- Sound Presets Selector
    local lblSoundChoice = pRelease:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lblSoundChoice:SetPoint("TOPLEFT", pRelease, "TOPLEFT", 10, -244)
    lblSoundChoice:SetText("Efecto de Audio:")

    local soundButtons = {}
    local soundOptions = {
        { key = "auto", label = "Auto", tooltip = "Easter Egg si estás en Distraction (Quel'Thalas), alarma táctica para todos los demás." },
        { key = "raid_warning", label = "Raid Alert", tooltip = "Alarma clásica limpia de Raid Warning de Blizzard." },
        { key = "alarm", label = "Alarma Digital", tooltip = "Tono digital táctico." },
        { key = "bane", label = "Bane Meme", tooltip = "Audio cómico clásico: ¡Burro, sonso, no liberes!" },
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
        local btnOpt = CreateFlatButton(pRelease, opt.label, 80, 20)
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
    f.RefreshSoundButtons = RefreshSoundButtons
    RefreshSoundButtons()

    -- Checkbox: Auto Release on Full Wipe in M+
    CreateCheckbox(pRelease, "M+ Wipe Total: Auto-liberar espíritu si muere todo el grupo", 8, -276, DQ.Config:Get("mythicPlus", "autoReleaseOnWipe"), function(checked)
        DQ.Config:Set("mythicPlus", "autoReleaseOnWipe", checked)
    end)
    local wipeDesc = pRelease:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    wipeDesc:SetPoint("TOPLEFT", pRelease, "TOPLEFT", 32, -302)
    wipeDesc:SetPoint("RIGHT", pRelease, "RIGHT", -12, 0)
    wipeDesc:SetJustifyH("LEFT")
    wipeDesc:SetText("|cff888888Desactiva la protección y libera al morir los 5 jugadores para ahorrar tiempo de piedra.|r")

    -- ==========================================================
    -- PAGE 2: RAID FLOW & READINESS
    -- ==========================================================
    local pFlow = tabPages["raidflow"]

    local flowTitle = pFlow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    flowTitle:SetPoint("TOPLEFT", pFlow, "TOPLEFT", 4, 0)
    flowTitle:SetText("|cff00e5ff" .. (L["SECTION_RAIDFLOW_TITLE"] or "Flujo de Banda & Preparación") .. "|r")

    local flowDesc = pFlow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    flowDesc:SetPoint("TOPLEFT", flowTitle, "BOTTOMLEFT", 0, -4)
    flowDesc:SetText(L["SECTION_RAIDFLOW_DESC"] or "Herramientas dirigidas por eventos para no perder llamadas mientras estás distraído.")

    -- Checkbox: Flash Taskbar
    CreateCheckbox(pFlow, L["FLASH_TASKBAR"] or "Parpadear ventana en barra de tareas en Ready Check / Pull", 8, -46, DQ.Config:Get("raidFlow", "flashTaskbar"), function(checked)
        DQ.Config:Set("raidFlow", "flashTaskbar", checked)
    end)

    -- Checkbox: Ready Check Sound
    CreateCheckbox(pFlow, L["READY_CHECK_SOUND"] or "Alerta sonora por canal Master en Ready Check", 8, -78, DQ.Config:Get("raidFlow", "readyCheckSound"), function(checked)
        DQ.Config:Set("raidFlow", "readyCheckSound", checked)
    end)

    -- Checkbox: Check Consumables at Ready Check
    CreateCheckbox(pFlow, L["CHECK_CONSUMABLES"] or "Avisar si faltan consumibles en Ready Check", 8, -110, DQ.Config:Get("raidFlow", "checkConsumables"), function(checked)
        DQ.Config:Set("raidFlow", "checkConsumables", checked)
    end)

    -- Checkbox: Warn Expiring Consumables (< 5 min)
    CreateCheckbox(pFlow, "Avisar en chat si consumibles expiran en < 5 min fuera de combate", 8, -142, DQ.Config:Get("raidFlow", "warnExpiringConsumables"), function(checked)
        DQ.Config:Set("raidFlow", "warnExpiringConsumables", checked)
    end)

    -- Checkbox: LFG Queue Proposal Alert
    CreateCheckbox(pFlow, "Parpadear barra de tareas y alerta sonora en llamada de buscador (LFG)", 8, -174, DQ.Config:Get("raidFlow", "lfgAlert"), function(checked)
        DQ.Config:Set("raidFlow", "lfgAlert", checked)
    end)

    -- Manual Consumables Check button
    local btnCheckNow = CreateFlatButton(pFlow, "Revisar Consumibles Ahora", 200, 24)
    btnCheckNow:SetPoint("TOPLEFT", pFlow, "TOPLEFT", 8, -214)
    btnCheckNow:SetScript("OnClick", function()
        if DQ.RaidFlow then DQ.RaidFlow:CheckConsumables(true) end
    end)

    -- Checkbox: Tooltip Targeted By
    CreateCheckbox(pFlow, "Tooltip de Mob: Mostrar qué miembros lo están enfocando (Targeted By)", 8, -256, DQ.Config:Get("tooltip", "targetedBy"), function(checked)
        DQ.Config:Set("tooltip", "targetedBy", checked)
    end)
    local ttDesc = pFlow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ttDesc:SetPoint("TOPLEFT", pFlow, "TOPLEFT", 32, -282)
    ttDesc:SetPoint("RIGHT", pFlow, "RIGHT", -12, 0)
    ttDesc:SetJustifyH("LEFT")
    ttDesc:SetText("|cff888888Agrega al tooltip del objetivo la cantidad y rol de jugadores que lo tienen en target (ej: 1T 1H 2D).|r")

    -- ==========================================================
    -- PAGE 3: AUTOMATIONS
    -- ==========================================================
    local pAuto = tabPages["automation"]

    local autoTitle = pAuto:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoTitle:SetPoint("TOPLEFT", pAuto, "TOPLEFT", 4, 0)
    autoTitle:SetText("|cff00e5ff" .. (L["SECTION_AUTO_TITLE"] or "Automatizaciones QoL") .. "|r")

    local autoDesc = pAuto:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    autoDesc:SetPoint("TOPLEFT", autoTitle, "BOTTOMLEFT", 0, -4)
    autoDesc:SetText(L["SECTION_AUTO_DESC"] or "Acciones instantáneas sin spam de eventos ni sobrecoste de CPU.")

    -- 1. Auto Res
    local cbAutoResCombat
    CreateCheckbox(pAuto, L["AUTO_RES"] or "Auto-aceptar Resurrección en wipes", 8, -46, DQ.Config:Get("automation", "autoRes", "enabled"), function(checked)
        DQ.Config:Set("automation", "autoRes", "enabled", checked)
        if cbAutoResCombat then
            cbAutoResCombat:SetEnabled(checked)
            cbAutoResCombat.text:SetTextColor(checked and 1 or 0.45, checked and 1 or 0.45, checked and 1 or 0.45)
        end
    end)

    cbAutoResCombat = CreateCheckbox(pAuto, L["AUTO_RES_COMBAT"] or "Permitir auto-aceptar en combate (Battle Rez)", 32, -72, DQ.Config:Get("automation", "autoRes", "inCombat"), function(checked)
        DQ.Config:Set("automation", "autoRes", "inCombat", checked)
    end)
    local autoResActive = DQ.Config:Get("automation", "autoRes", "enabled")
    cbAutoResCombat:SetEnabled(autoResActive)
    cbAutoResCombat.text:SetTextColor(autoResActive and 1 or 0.45, autoResActive and 1 or 0.45, autoResActive and 1 or 0.45)

    -- 2. Auto Repair & Guild Repair
    local cbGuildRepair
    CreateCheckbox(pAuto, L["AUTO_REPAIR"] or "Auto-reparar equipo en mercader", 8, -102, DQ.Config:Get("automation", "autoRepair"), function(checked)
        DQ.Config:Set("automation", "autoRepair", checked)
        if cbGuildRepair then
            cbGuildRepair:SetEnabled(checked)
            cbGuildRepair.text:SetTextColor(checked and 1 or 0.45, checked and 1 or 0.45, checked and 1 or 0.45)
        end
    end)

    cbGuildRepair = CreateCheckbox(pAuto, L["GUILD_REPAIR"] or "Priorizar fondos de hermandad para reparaciones", 32, -128, DQ.Config:Get("automation", "guildRepair"), function(checked)
        DQ.Config:Set("automation", "guildRepair", checked)
    end)
    local repairActive = DQ.Config:Get("automation", "autoRepair")
    cbGuildRepair:SetEnabled(repairActive)
    cbGuildRepair.text:SetTextColor(repairActive and 1 or 0.45, repairActive and 1 or 0.45, repairActive and 1 or 0.45)

    -- 3. Auto Sell Junk
    CreateCheckbox(pAuto, L["AUTO_SELL_JUNK"] or "Auto-vender basura gris en mercader", 8, -158, DQ.Config:Get("automation", "autoSellJunk"), function(checked)
        DQ.Config:Set("automation", "autoSellJunk", checked)
    end)

    -- 4. Auto Skip Movies
    CreateCheckbox(pAuto, L["AUTO_SKIP_MOVIES"] or "Auto-saltar cinemáticas ya vistas en bosses", 8, -186, DQ.Config:Get("automation", "autoSkipCinematics"), function(checked)
        DQ.Config:Set("automation", "autoSkipCinematics", checked)
    end)

    -- 5. Block Duels
    CreateCheckbox(pAuto, L["BLOCK_DUELS"] or "Bloquear invitaciones a duelos dentro de mazmorras/raid", 8, -214, DQ.Config:Get("automation", "blockDuels"), function(checked)
        DQ.Config:Set("automation", "blockDuels", checked)
    end)

    -- 6. Fast Loot
    CreateCheckbox(pAuto, L["FAST_LOOT"] or "Despojo rápido instantáneo (Fast Loot a 0ms)", 8, -242, DQ.Config:Get("automation", "fastLoot"), function(checked)
        DQ.Config:Set("automation", "fastLoot", checked)
    end)

    -- 7. Reverse Bag Sort & Reagents Stash
    CreateCheckbox(pAuto, L["BAG_SORT_BUTTON"] or "Mostrar botón de Orden Inverso en las bolsas", 8, -270, DQ.Config:Get("automation", "bagSortButton"), function(checked)
        DQ.Config:Set("automation", "bagSortButton", checked)
        if DQ.BagSort and DQ.BagSort.UpdateBagButtonVisibility then
            DQ.BagSort:UpdateBagButtonVisibility()
        end
    end)

    -- 8. EllesmereUI Sort Override
    CreateCheckbox(pAuto, L["OVERRIDE_ELLESMERE_SORT"] or "EllesmereUI: Reemplazar su botón de ordenar con DistractionQoL", 8, -298, DQ.Config:Get("automation", "overrideEllesmereSort"), function(checked)
        DQ.Config:Set("automation", "overrideEllesmereSort", checked)
        if DQ.BagSort and DQ.BagSort.UpdateEllesmereIntegration then
            DQ.BagSort:UpdateEllesmereIntegration()
        end
    end)

    -- 9. Mythic+ Keystone Auto-Slot
    CreateCheckbox(pAuto, "M+ Auto-Piedra: Insertar automáticamente llave en el pedestal (0ms)", 8, -326, DQ.Config:Get("mythicPlus", "autoSlot"), function(checked)
        DQ.Config:Set("mythicPlus", "autoSlot", checked)
    end)

    -- 10. Mythic+ Keystone Announce
    CreateCheckbox(pAuto, "M+ Anuncio: Notificar al grupo en chat la piedra insertada", 32, -352, DQ.Config:Get("mythicPlus", "announceSlot"), function(checked)
        DQ.Config:Set("mythicPlus", "announceSlot", checked)
    end)

    local btnSortNow = CreateFlatButton(pAuto, L["BTN_SORT_BAGS"] or "Ordenar Bolsas Ahora", 180, 22)
    btnSortNow:SetPoint("TOPLEFT", pAuto, "TOPLEFT", 8, -384)
    btnSortNow:SetScript("OnClick", function()
        if DQ.BagSort then DQ.BagSort:SortBags() end
    end)

    -- ==========================================================
    -- PAGE 4: PERFORMANCE & FPS OPTIMIZER
    -- ==========================================================
    local pPerf = tabPages["performance"]

    local perfTitle = pPerf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    perfTitle:SetPoint("TOPLEFT", pPerf, "TOPLEFT", 4, 0)
    perfTitle:SetText("|cff00e5ff" .. (L["SECTION_FPS_TITLE"] or "Optimización Gráfica en Raid") .. "|r")

    local statusFps = pPerf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusFps:SetPoint("TOPLEFT", perfTitle, "BOTTOMLEFT", 0, -8)
    f.statusFps = statusFps

    local statusBackup = pPerf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusBackup:SetPoint("TOPLEFT", statusFps, "BOTTOMLEFT", 0, -4)
    f.statusBackup = statusBackup

    -- Clean loading GC
    CreateCheckbox(pPerf, L["CLEAN_LOADING_GC"] or "Limpieza de memoria en pantallas de carga", 8, -64, DQ.Config:Get("fps", "cleanLoadingGC"), function(checked)
        DQ.Config:Set("fps", "cleanLoadingGC", checked)
    end)

    local noteFps = pPerf:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    noteFps:SetPoint("TOPLEFT", pPerf, "TOPLEFT", 8, -100)
    noteFps:SetPoint("RIGHT", pPerf, "RIGHT", -8, 0)
    noteFps:SetJustifyH("LEFT")
    noteFps:SetWordWrap(true)
    noteFps:SetText(L["FPS_NOTE"] or "|cff00e5ff* Mantiene activas las proyecciones en el suelo para ver todas las áreas de mecánicas.|r")

    -- Buttons row for FPS
    local btnFpsSave = CreateFlatButton(pPerf, L["BTN_FPS_SAVE"] or "Guardar Actual", 130, 26)
    btnFpsSave:SetPoint("TOPLEFT", pPerf, "TOPLEFT", 8, -145)
    btnFpsSave:SetScript("OnClick", function()
        if DQ.Optimizer then DQ.Optimizer:SaveBackup() end
        DQ.UI:UpdateFPSControls()
    end)

    local btnFpsOpt = CreateFlatButton(pPerf, L["BTN_FPS_OPT"] or "Optimizar FPS", 140, 26)
    btnFpsOpt:SetPoint("LEFT", btnFpsSave, "RIGHT", 10, 0)
    btnFpsOpt:SetScript("OnClick", function()
        if DQ.Optimizer then DQ.Optimizer:ApplyOptimal() end
    end)

    local btnFpsRestore = CreateFlatButton(pPerf, L["BTN_FPS_RESTORE"] or "Restaurar", 130, 26)
    btnFpsRestore:SetPoint("LEFT", btnFpsOpt, "RIGHT", 10, 0)
    btnFpsRestore:SetScript("OnClick", function()
        if DQ.Optimizer then DQ.Optimizer:RestoreOriginal() end
    end)

    -- ==========================================================
    -- PAGE 5: CONFLICTS & COMPATIBILITY
    -- ==========================================================
    local pConflicts = tabPages["conflicts"]

    local confTitle = pConflicts:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    confTitle:SetPoint("TOPLEFT", pConflicts, "TOPLEFT", 4, 0)
    confTitle:SetText("|cff00e5ff" .. (L["SECTION_CONFLICTS_TITLE"] or "Resolución de Conflictos & Compatibilidad") .. "|r")

    local confDesc = pConflicts:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    confDesc:SetPoint("TOPLEFT", confTitle, "BOTTOMLEFT", 0, -4)
    confDesc:SetPoint("RIGHT", pConflicts, "RIGHT", -4, 0)
    confDesc:SetJustifyH("LEFT")
    confDesc:SetWordWrap(true)
    confDesc:SetText(L["SECTION_CONFLICTS_DESC"] or "Detecta funciones compartidas con EllesmereUI y ElvUI. Puedes definir qué addon controla cada función o restablecer los avisos emergentes.")

    local conflictRows = {}
    local featureOrder = { "autoRepair", "autoSellJunk", "fastLoot", "autoSkipCinematics", "bagSort" }

    local function RefreshConflictRows()
        if not DQ.ConflictResolver then return end
        local defs = DQ.ConflictResolver.DEFINITIONS or {}

        for _, key in ipairs(featureOrder) do
            local def = defs[key]
            local row = conflictRows[key]
            if def and row then
                local ext = DQ.ConflictResolver:DetectConflict(key)
                local currentChoice = DQ.ConflictResolver:GetChoice(key) or "DistractionQoL"

                if ext then
                    local statusFmt = L["CONFLICT_ACTIVE_WITH"] or "Conflicto con: |cffffcc00%s|r"
                    row.statusText:SetText(string.format(statusFmt, ext))
                    row.btnExt:SetButtonText(ext)
                    row.btnExt:Show()

                    if currentChoice == "DistractionQoL" then
                        row.btnDQ:SetBackdropColor(0.0, 0.40, 0.50, 0.9)
                        row.btnDQ:SetBackdropBorderColor(0.0, 0.85, 1.0, 1)
                        row.btnExt:SetBackdropColor(0.12, 0.12, 0.16, 0.8)
                        row.btnExt:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
                    else
                        row.btnDQ:SetBackdropColor(0.12, 0.12, 0.16, 0.8)
                        row.btnDQ:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
                        row.btnExt:SetBackdropColor(0.40, 0.20, 0.55, 0.9)
                        row.btnExt:SetBackdropBorderColor(0.70, 0.45, 0.95, 1)
                    end
                else
                    row.statusText:SetText(L["CONFLICT_NONE"] or "|cff888888Sin conflicto detectado|r")
                    row.btnExt:Hide()
                    row.btnDQ:SetBackdropColor(0.0, 0.40, 0.50, 0.9)
                    row.btnDQ:SetBackdropBorderColor(0.0, 0.85, 1.0, 1)
                end
            end
        end
    end

    local rowStartY = -42
    local rowHeight = 48

    for i, key in ipairs(featureOrder) do
        local def = (DQ.ConflictResolver and DQ.ConflictResolver.DEFINITIONS and DQ.ConflictResolver.DEFINITIONS[key]) or {}
        local isSpanish = (GetLocale() == "esES" or GetLocale() == "esMX")
        local name = isSpanish and (def.name or key) or (def.nameEn or key)

        local rowY = rowStartY - (i - 1) * rowHeight

        local rowBg = pConflicts:CreateTexture(nil, "BACKGROUND")
        rowBg:SetPoint("TOPLEFT", pConflicts, "TOPLEFT", 0, rowY)
        rowBg:SetPoint("BOTTOMRIGHT", pConflicts, "TOPRIGHT", 0, rowY - (rowHeight - 6))
        rowBg:SetColorTexture(0.10, 0.10, 0.14, 0.45)

        local icon = pConflicts:CreateTexture(nil, "ARTWORK")
        icon:SetSize(26, 26)
        icon:SetPoint("LEFT", pConflicts, "TOPLEFT", 8, rowY - 21)
        icon:SetTexture(def.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

        local lblName = pConflicts:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lblName:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 2)
        lblName:SetText("|cffffffff" .. name .. "|r")

        local lblStatus = pConflicts:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        lblStatus:SetPoint("TOPLEFT", lblName, "BOTTOMLEFT", 0, -2)
        lblStatus:SetText("Verificando...")

        local btnDQ = CreateFlatButton(pConflicts, "DistractionQoL", 100, 22)
        btnDQ:SetPoint("RIGHT", pConflicts, "TOPRIGHT", -114, rowY - 21)
        btnDQ:SetScript("OnClick", function()
            if DQ.ConflictResolver then
                DQ.ConflictResolver:SetChoice(key, "DistractionQoL", true)
                RefreshConflictRows()
            end
        end)

        local btnExt = CreateFlatButton(pConflicts, "Externo", 100, 22)
        btnExt:SetPoint("RIGHT", pConflicts, "TOPRIGHT", -8, rowY - 21)
        btnExt:SetScript("OnClick", function()
            if DQ.ConflictResolver then
                DQ.ConflictResolver:SetChoice(key, "External", true)
                RefreshConflictRows()
            end
        end)

        conflictRows[key] = {
            icon = icon,
            nameText = lblName,
            statusText = lblStatus,
            btnDQ = btnDQ,
            btnExt = btnExt,
        }
    end

    local btnResetConflicts = CreateFlatButton(pConflicts, L["BTN_RESET_CONFLICTS"] or "Restablecer Avisos (Volver a Preguntar)", 270, 24)
    btnResetConflicts:SetPoint("BOTTOMLEFT", pConflicts, "BOTTOMLEFT", 4, 8)
    btnResetConflicts:SetScript("OnClick", function()
        if DQ.ConflictResolver then
            DQ.ConflictResolver:ResetAllChoices()
            RefreshConflictRows()
        end
    end)

    pConflicts:SetScript("OnShow", function()
        RefreshConflictRows()
    end)

    -- ==========================================================
    -- BOTTOM ACTION BAR (Common to all tabs)
    -- ==========================================================
    local bottomBar = f:CreateTexture(nil, "BACKGROUND")
    bottomBar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
    bottomBar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    bottomBar:SetHeight(48)
    bottomBar:SetColorTexture(0, 0, 0, 0.40)

    local btnW = 100
    local btnH = 26
    local bY = 12

    local btnTest = CreateFlatButton(f, L["BTN_TEST"] or "Probar Alerta", btnW, btnH)
    btnTest:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, bY)
    btnTest:SetScript("OnClick", function()
        DQ.Alert:Trigger()
    end)

    local btnSim = CreateFlatButton(f, L["BTN_SIM"] or "Simular Muerte", btnW, btnH)
    btnSim:SetPoint("LEFT", btnTest, "RIGHT", 8, 0)
    btnSim:SetScript("OnClick", function()
        DQ.Detection.simMode = true
        DQ.Hook:Init()
        local prefix = "|cff00e5ff[DistractionQoL]|r "
        local msg = prefix .. (L["MSG_SIM_START"] or "|cffffcc00Modo simulación activo:|r Ventana de liberación abierta.\n1. Un clic normal será bloqueado y activará la alerta.\n2. Mantén presionado SHIFT y haz clic para cerrar.")
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage(msg)
        elseif print then
            print(msg)
        end
        StaticPopup_Show("DEATH")
    end)

    local btnMute = CreateFlatButton(f, "", 140, btnH)
    btnMute:SetPoint("LEFT", btnSim, "RIGHT", 8, 0)
    btnMute:SetScript("OnClick", function()
        local current = DQ.Config:Get("releaseGuard", "soundEnabled") ~= false
        local newVal = not current
        DQ.Config:Set("releaseGuard", "soundEnabled", newVal)
        DQ.UI:UpdateSoundControls()
    end)
    f.btnMute = btnMute

    local btnClose = CreateFlatButton(f, L["BTN_CLOSE"] or "Cerrar", 85, btnH)
    btnClose:SetPoint("LEFT", btnMute, "RIGHT", 8, 0)
    btnClose:SetScript("OnClick", function()
        f:Hide()
    end)

    -- Default to first tab
    ShowTab("release")

    configFrame = f
    self.frame = f

    self:UpdateSoundControls()
    self:UpdateFPSControls()
    self:CheckSkinning()

    return f
end

-- Updates Sound button and checkbox state with dynamic sound icon
function DQ.UI:UpdateSoundControls()
    if not configFrame then return end
    local L = DQ.L or {}
    local soundOn = DQ.Config:Get("releaseGuard", "soundEnabled") ~= false
    local iconStr = GetSoundIcon(soundOn, 14)

    if configFrame.btnMute then
        local label = soundOn and (L["BTN_MUTE"] or "Mutear Sonido") or (L["BTN_UNMUTE"] or "Activar Sonido")
        configFrame.btnMute:SetButtonText(iconStr .. label)
        if not configFrame.btnMute.isSkinned then
            if soundOn then
                configFrame.btnMute:SetBackdropBorderColor(0.24, 0.24, 0.30, 1)
            else
                configFrame.btnMute:SetBackdropBorderColor(0.85, 0.20, 0.20, 1) -- Red highlight when muted
            end
        end
    end
    if configFrame.cbSound then
        configFrame.cbSound:SetChecked(soundOn)
    end
    if configFrame.soundStatusIcon then
        configFrame.soundStatusIcon:SetTexture(ResolveSoundPath(soundOn))
    end
end

-- Updates FPS status text
function DQ.UI:UpdateFPSControls()
    if not configFrame then return end
    local L = DQ.L or {}

    if configFrame.statusFps and DQ.Optimizer then
        local isOpt = DQ.Optimizer:IsOptimized()
        local modeStr = isOpt and (L["FPS_STATUS_OPT"] or "|cff00ff00MÁXIMO FPS ACTIVO|r")
                              or  (L["FPS_STATUS_NORMAL"] or "|cffaaaaaaOriginal / Estándar|r")
        configFrame.statusFps:SetText(string.format(L["FPS_STATUS_LABEL"] or "Modo Gráfico: %s", modeStr))
    end

    if configFrame.statusBackup and DQ.Optimizer then
        local hasBk = DQ.Optimizer:HasBackup()
        local count = 0
        local backup = DQ.Config:Get("fps", "backup")
        if backup and type(backup) == "table" then
            for _ in pairs(backup) do count = count + 1 end
        end
        local bkStr = hasBk and string.format(L["FPS_BACKUP_SAVED"] or "|cff00ff00Sí (%d opciones)|r", count)
                            or (L["FPS_BACKUP_NONE"] or "|cffffaa00No guardada|r")
        configFrame.statusBackup:SetText(string.format(L["FPS_BACKUP_LABEL"] or "Copia guardada: %s", bkStr))
    end
end

-- Skinning support for EllesmereUI
function DQ.UI:ApplyEllesmereSkin(S)
    if not configFrame or configFrame.isSkinned then return end
    configFrame.isSkinned = true

    if S.HandleFrame then
        S:HandleFrame(configFrame)
    end
    if S.HandleCloseButton and configFrame.CloseButton then
        if configFrame.CloseButton.xText then configFrame.CloseButton.xText:Hide() end
        S:HandleCloseButton(configFrame.CloseButton)
    end
end

-- Skinning support for ElvUI
function DQ.UI:ApplyElvUISkin()
    if not configFrame or configFrame.isSkinned or not ElvUI then return end
    local E = ElvUI[1]
    local S = E and E:GetModule("Skins")
    if not S then return end

    configFrame.isSkinned = true
    if S.HandleFrame then
        S:HandleFrame(configFrame, true, nil, 0, 0, 0, 0)
    end
    if S.HandleCloseButton and configFrame.CloseButton then
        if configFrame.CloseButton.xText then configFrame.CloseButton.xText:Hide() end
        S:HandleCloseButton(configFrame.CloseButton)
    end
end

-- Checks and dispatches skinning
function DQ.UI:CheckSkinning()
    if not configFrame or configFrame.isSkinned then return end
    if self.euiSkinFacade then
        self:ApplyEllesmereSkin(self.euiSkinFacade)
    elseif ElvUI then
        self:ApplyElvUISkin()
    end
end

-- Register skinning callback with EllesmereUI's official public API
if EllesmereUI and EllesmereUI.RegisterSkin then
    local skinFunc = function(S)
        DQ.UI.euiSkinFacade = S
        DQ.UI:ApplyEllesmereSkin(S)
    end
    EllesmereUI.RegisterSkin("DistractionQoL", skinFunc)
end

-- Toggles configuration panel visibility
function DQ.UI:Toggle()
    local panel = self:CreatePanel()
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
    end
end

-- Registers addon in modern Game Menu -> Options -> AddOns (Settings API)
function DQ.UI:RegisterSettingsCategory()
    if not Settings or not Settings.RegisterCanvasLayoutCategory or not Settings.RegisterAddOnCategory then
        return
    end

    local L = DQ.L or {}
    local panel = CreateFrame("Frame", "DistractionQoLSettingsCanvas", UIParent)
    panel.name = "DistractionQoL"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText((L["CONFIG_TITLE"] or "|cff00e5ffDistractionQoL|r") .. " |cff888888v2.0.1 (WoW 12.1.5)|r")

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText(L["SETTINGS_DESC"] or "Herramientas de QoL y rendimiento ultraligero para Raiders.\nEscribe /qol para abrir el panel:")

    local openBtn = CreateFlatButton(panel, L["BTN_OPEN_CONFIG"] or "Open Configuration", 220, 30)
    openBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
    openBtn:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
        end
        DQ.UI:Toggle()
    end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    category.ID = panel.name
    Settings.RegisterAddOnCategory(category)
    self.settingsCategory = category
end
