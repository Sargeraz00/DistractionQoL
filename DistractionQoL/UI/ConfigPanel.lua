-- ConfigPanel.lua
-- Settings console with modern flat obsidian styling and tabbed navigation
-- Modular tab controller integrating Release Guard, Raid Flow, Automations, Performance, and Compatibility
-- Fully compatible with EllesmereUI (Official Skinning API) and ElvUI (Skins Module)
-- Fully localized and integrated with WoW 12.1.0+ Settings API

local addonName, DQ = ...

DQ.UI = DQ.UI or {}

local configFrame = nil

-- Builds the configuration panel frame with modern sidebar navigation
function DQ.UI:CreatePanel()
    if configFrame then return configFrame end

    local L = DQ.L or {}
    local versionStr = DQ.Util and DQ.Util.GetVersion and DQ.Util.GetVersion() or "4.0.0"

    -- Main Frame with modern flat obsidian backdrop (720x520)
    local f = CreateFrame("Frame", "DistractionQoLConfigFrame", UIParent, "BackdropTemplate")
    f:SetSize(720, 520)
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
    title:SetText((L["CONFIG_TITLE"] or "|cff00e5ffDistractionQoL|r") .. " |cff888888v" .. versionStr .. "|r")
    f.title = title
    f.TitleText = title

    -- Top-right close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -3)
    closeBtn:SetScript("OnClick", function()
        if not InCombatLockdown or not InCombatLockdown() then
            f:Hide()
        end
    end)

    local xText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xText:SetPoint("CENTER", closeBtn, "CENTER", 0, 1)
    xText:SetText("|cffaaaaaaX|r")
    closeBtn.xText = xText

    closeBtn:HookScript("OnEnter", function(self)
        if not self.isSkinned and self.xText then self.xText:SetText("|cffff3333X|r") end
    end)
    closeBtn:HookScript("OnLeave", function(self)
        if not self.isSkinned and self.xText then self.xText:SetText("|cffaaaaaaX|r") end
    end)

    f.CloseButton = closeBtn
    f.Close = closeBtn

    -- Shortcut button to open the Setup Wizard
    local btnWizard = CreateFrame("Button", nil, f, "BackdropTemplate")
    btnWizard:SetSize(110, 18)
    btnWizard:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)
    btnWizard:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    btnWizard:SetBackdropColor(0.12, 0.12, 0.16, 0.9)
    btnWizard:SetBackdropBorderColor(0.0, 0.70, 0.85, 0.8)

    local wizText = btnWizard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    wizText:SetPoint("CENTER")
    wizText:SetText("|cff00e5ff[|r " .. (L["WIZARD_BUTTON"] or "Asistente") .. " |cff00e5ff]|r")
    btnWizard.text = wizText

    btnWizard:SetScript("OnClick", function()
        f:Hide()
        if DQ.Wizard and DQ.Wizard.Open then
            DQ.Wizard:Open()
        end
    end)
    btnWizard:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.0, 0.40, 0.50, 1)
        self:SetBackdropBorderColor(0.0, 0.90, 1.0, 1)
    end)
    btnWizard:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.16, 0.9)
        self:SetBackdropBorderColor(0.0, 0.70, 0.85, 0.8)
    end)

    -- ==========================================================
    -- MODERN LEFT SIDEBAR NAVIGATION
    -- ==========================================================
    local sidebar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -27)
    sidebar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 48)
    sidebar:SetWidth(155)
    sidebar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    sidebar:SetBackdropColor(0.04, 0.04, 0.06, 0.98)
    sidebar:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)
    f.sidebar = sidebar

    local tabDefs = {
        { id = "release",     icon = "Interface\\Icons\\Spell_Holy_Resurrection",           label = L["TAB_RELEASE"] or "Liberación" },
        { id = "raidflow",    icon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings", label = L["TAB_RAIDFLOW"] or "Flujo Raid" },
        { id = "automation",  icon = "Interface\\Icons\\INV_Gizmo_02",                      label = L["TAB_AUTOMATION"] or "Automatiz." },
        { id = "tooltips",    icon = "Interface\\Icons\\INV_Misc_Bag_08",                   label = L["TAB_TOOLTIPS"] or "Tooltips & Botín" },
        { id = "performance", icon = "Interface\\Icons\\Spell_Nature_Invisibilty",          label = L["TAB_PERFORMANCE"] or "Rendimiento" },
        { id = "conflicts",   icon = "Interface\\Icons\\INV_Misc_Gear_01",                  label = L["TAB_CONFLICTS"] or "Compatibilidad" },
    }

    local tabButtons = {}
    local tabPages = {}
    local activeTab = "release"

    local function ShowTab(tabId)
        activeTab = tabId
        for _, def in ipairs(tabDefs) do
            local page = tabPages[def.id]
            local btn = tabButtons[def.id]
            local isSelected = (def.id == tabId)
            if isSelected then
                if page then page:Show() end
                if btn and not btn.isSkinned then
                    btn:SetBackdropColor(0.0, 0.35, 0.45, 0.9)
                    btn:SetBackdropBorderColor(0.0, 0.85, 0.95, 1)
                    if btn.indicator then btn.indicator:Show() end
                    if btn.text then btn.text:SetTextColor(1, 1, 1, 1) end
                end
            else
                if page then page:Hide() end
                if btn and not btn.isSkinned then
                    btn:SetBackdropColor(0.08, 0.08, 0.11, 0.8)
                    btn:SetBackdropBorderColor(0.15, 0.15, 0.18, 0.8)
                    if btn.indicator then btn.indicator:Hide() end
                    if btn.text then btn.text:SetTextColor(0.70, 0.70, 0.75, 1) end
                end
            end
        end
    end

    local btnHeight = 34
    local btnWidth = 151
    local btnSpacing = 3

    for i, def in ipairs(tabDefs) do
        local btn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        btn:SetSize(btnWidth, btnHeight)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 2, -4 - ((i - 1) * (btnHeight + btnSpacing)))
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        btn:SetBackdropColor(0.08, 0.08, 0.11, 0.8)
        btn:SetBackdropBorderColor(0.15, 0.15, 0.18, 0.8)

        -- Left Active Indicator Strip (3px)
        local indicator = btn:CreateTexture(nil, "OVERLAY")
        indicator:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        indicator:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
        indicator:SetWidth(3)
        indicator:SetColorTexture(0.0, 0.85, 0.95, 1)
        indicator:Hide()
        btn.indicator = indicator

        -- Category Icon
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", btn, "LEFT", 8, 0)
        icon:SetTexture(def.icon)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        btn.icon = icon

        -- Category Label
        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btnText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        btnText:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
        btnText:SetJustifyH("LEFT")
        btnText:SetWordWrap(false)
        btnText:SetText(def.label)
        btn.text = btnText

        btn:SetScript("OnClick", function()
            ShowTab(def.id)
        end)
        btn:SetScript("OnEnter", function(self)
            if activeTab ~= def.id and not self.isSkinned then
                self:SetBackdropColor(0.13, 0.13, 0.18, 0.95)
                self:SetBackdropBorderColor(0.30, 0.30, 0.38, 1)
                if self.text then self.text:SetTextColor(0.95, 0.95, 0.95, 1) end
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if activeTab ~= def.id and not self.isSkinned then
                self:SetBackdropColor(0.08, 0.08, 0.11, 0.8)
                self:SetBackdropBorderColor(0.15, 0.15, 0.18, 0.8)
                if self.text then self.text:SetTextColor(0.70, 0.70, 0.75, 1) end
            end
        end)

        tabButtons[def.id] = btn

        -- Container page for this tab (Width ~544px, Height ~440px)
        local page = CreateFrame("Frame", nil, f)
        page:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, 0)
        page:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 52)
        tabPages[def.id] = page
    end

    -- ==========================================================
    -- TAB PAGE BUILDERS (Modular delegation)
    -- ==========================================================
    if self.BuildTabRelease then
        self:BuildTabRelease(f, tabPages["release"])
    end
    if self.BuildTabRaidFlow then
        self:BuildTabRaidFlow(f, tabPages["raidflow"])
    end
    if self.BuildTabAutomations then
        self:BuildTabAutomations(f, tabPages["automation"])
    end
    if self.BuildTabTooltips then
        self:BuildTabTooltips(f, tabPages["tooltips"])
    end
    if self.BuildTabPerformance then
        self:BuildTabPerformance(f, tabPages["performance"])
    end
    if self.BuildTabCompatibility then
        self:BuildTabCompatibility(f, tabPages["conflicts"])
    end

    -- ==========================================================
    -- BOTTOM ACTION BAR (Common to all tabs)
    -- ==========================================================
    local bottomBar = f:CreateTexture(nil, "BACKGROUND")
    bottomBar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
    bottomBar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    bottomBar:SetHeight(48)
    bottomBar:SetColorTexture(0, 0, 0, 0.40)

    local btnW = 110
    local btnH = 26
    local bY = 12

    local btnTest = self:CreateFlatButton(f, L["BTN_TEST"] or "Probar Alerta", btnW, btnH)
    btnTest:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, bY)
    btnTest:SetScript("OnClick", function()
        DQ.Alert:Trigger()
    end)

    local btnSim = self:CreateFlatButton(f, L["BTN_SIM"] or "Simular Muerte", btnW, btnH)
    btnSim:SetPoint("LEFT", btnTest, "RIGHT", 8, 0)
    btnSim:SetScript("OnClick", function()
        if DQ.Detection and DQ.Detection.StartSimulation then
            DQ.Detection:StartSimulation()
        end
    end)

    local btnMute = self:CreateFlatButton(f, "", 140, btnH)
    btnMute:SetPoint("LEFT", btnSim, "RIGHT", 8, 0)
    btnMute:SetScript("OnClick", function()
        local current = DQ.Config:Get("releaseGuard", "soundEnabled") ~= false
        local newVal = not current
        DQ.Config:Set("releaseGuard", "soundEnabled", newVal)
        DQ.UI:UpdateSoundControls()
    end)
    f.btnMute = btnMute

    local btnClose = self:CreateFlatButton(f, L["BTN_CLOSE"] or "Cerrar", 85, btnH)
    btnClose:SetPoint("RIGHT", f, "BOTTOMRIGHT", -14, bY)
    btnClose:SetScript("OnClick", function()
        if not InCombatLockdown or not InCombatLockdown() then
            f:Hide()
        end
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
    local iconStr = self:GetSoundIcon(soundOn, 14)

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
        configFrame.soundStatusIcon:SetTexture(self:ResolveSoundPath(soundOn))
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

    local verStr = DQ.Util and DQ.Util.GetVersion and DQ.Util.GetVersion() or "4.0.0"
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText((L["CONFIG_TITLE"] or "|cff00e5ffDistractionQoL|r") .. " |cff888888v" .. verStr .. "|r")

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText(L["SETTINGS_DESC"] or "Herramientas de QoL y rendimiento ultraligero para Raiders.\nEscribe /qol para abrir el panel:")

    local openBtn = self:CreateFlatButton(panel, L["BTN_OPEN_CONFIG"] or "Open Configuration", 220, 30)
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

-- Reactive Config subscriptions
if DQ.Config and DQ.Config.RegisterCallback then
    DQ.Config:RegisterCallback("releaseGuard.soundEnabled", function()
        if DQ.UI and DQ.UI.UpdateSoundControls then
            DQ.UI:UpdateSoundControls()
        end
    end)
    DQ.Config:RegisterCallback("fps.optimized", function()
        if DQ.UI and DQ.UI.UpdateFPSControls then
            DQ.UI:UpdateFPSControls()
        end
    end)
end
