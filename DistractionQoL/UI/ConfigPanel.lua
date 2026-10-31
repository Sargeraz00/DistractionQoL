-- ConfigPanel.lua
-- Settings console with modern flat obsidian styling and tabbed navigation
-- Modular tab controller integrating Release Guard, Raid Flow, Automations, Performance, and Compatibility
-- Fully compatible with EllesmereUI (Official Skinning API) and ElvUI (Skins Module)
-- Fully localized and integrated with WoW 12.1.0+ Settings API

local addonName, DQ = ...

DQ.UI = DQ.UI or {}

local configFrame = nil

-- Builds the configuration panel frame with modern Material Design 3 (M3) navigation
function DQ.UI:CreatePanel()
    if configFrame then return configFrame end

    local L = DQ.L or {}
    local versionStr = DQ.Util and DQ.Util.GetVersion and DQ.Util.GetVersion() or "4.2.3"
    local m3 = (DQ.Theme and DQ.Theme.M3) or {}

    -- Main Window with M3 Tonal Surface (740x530)
    local f = CreateFrame("Frame", "DistractionQoLConfigFrame", UIParent, "BackdropTemplate")
    f:SetSize(740, 530)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    if DQ.Theme and DQ.Theme.ApplyWindowStyle then
        DQ.Theme.ApplyWindowStyle(f)
    end

    -- ==========================================================
    -- M3 TOP APP BAR (Spacious 46px Header)
    -- ==========================================================
    local appBar = f:CreateTexture(nil, "BACKGROUND", nil, -5)
    appBar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    appBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    appBar:SetHeight(46)
    appBar:SetColorTexture(unpack(m3.surfaceContainerLowest or { 0.06, 0.06, 0.08, 0.98 }))
    f.appBar = appBar

    -- App Bar Bottom Divider (Subtle 1px M3 Outline)
    local barDivider = f:CreateTexture(nil, "ARTWORK")
    barDivider:SetPoint("TOPLEFT", appBar, "BOTTOMLEFT", 0, 0)
    barDivider:SetPoint("TOPRIGHT", appBar, "BOTTOMRIGHT", 0, 0)
    barDivider:SetHeight(1)
    barDivider:SetColorTexture(unpack(m3.outlineVariant or { 0.16, 0.17, 0.21, 0.40 }))

    -- App Brand Icon
    local appIconFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
    appIconFrame:SetSize(28, 28)
    appIconFrame:SetPoint("LEFT", f, "TOPLEFT", 14, -23)
    appIconFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    appIconFrame:SetBackdropColor(unpack(m3.surfaceContainerLow or { 0.06, 0.13, 0.15, 0.95 }))
    appIconFrame:SetBackdropBorderColor(unpack(m3.outline or { 0.31, 0.36, 0.38, 0.55 }))

    local appIcon = appIconFrame:CreateTexture(nil, "ARTWORK")
    appIcon:SetSize(24, 24)
    appIcon:SetPoint("CENTER")
    appIcon:SetTexture("Interface\\Icons\\Spell_Shadow_DeathScream")
    appIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- App Title
    local fontBold = (DQ.Theme and DQ.Theme.GetFont and DQ.Theme.GetFont("bold")) or "Fonts\\FRIZQT__.TTF"
    local fontSemiBold = (DQ.Theme and DQ.Theme.GetFont and DQ.Theme.GetFont("semibold")) or "Fonts\\FRIZQT__.TTF"
    local fontRegular = (DQ.Theme and DQ.Theme.GetFont and DQ.Theme.GetFont("regular")) or "Fonts\\FRIZQT__.TTF"

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(fontBold, 15, "")
    title:SetShadowOffset(0, 0)
    title:SetPoint("LEFT", appIconFrame, "RIGHT", 10, 4)
    title:SetTextColor(unpack(m3.onSurface or { 0.90, 0.91, 0.94, 1.0 }))
    title:SetText("DistractionQoL  |cff78909cv" .. versionStr .. "|r")
    f.title = title
    f.TitleText = title

    -- Subtitle / Expansion Info
    local subTitle = f:CreateFontString(nil, "OVERLAY")
    subTitle:SetFont(fontRegular, 11, "")
    subTitle:SetShadowOffset(0, 0)
    subTitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    subTitle:SetTextColor(unpack(m3.onSurfaceVariant or { 0.65, 0.70, 0.74, 1.0 }))
    subTitle:SetText(L["SUBTITLE_EXPANSION"] or "World of Warcraft: Midnight • Temporada 2")

    -- Top-Right Close Button (Modern M3 Icon Button, 28x28 centered in 46px app bar)
    local closeBtn = self:CreateM3IconButton(f, self:GetIconPath("m3_close.png"), 28, L["BTN_CLOSE"] or "Cerrar", function()
        if not InCombatLockdown or not InCombatLockdown() then
            f:Hide()
        end
    end)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -9)
    f.CloseButton = closeBtn
    f.Close = closeBtn

    -- Setup Wizard Shortcut Button (Modern M3 Tonal Button, anchored independently)
    local btnWizard = self:CreateM3Button(f, L["WIZARD_BUTTON"] or "Asistente", "tonal", 112, 26, self:GetIconPath("m3_wizard.png"))
    btnWizard:SetPoint("TOPRIGHT", f, "TOPRIGHT", -46, -10)
    btnWizard:SetScript("OnClick", function()
        f:Hide()
        if DQ.Wizard and DQ.Wizard.Open then
            DQ.Wizard:Open()
        end
    end)

    -- ==========================================================
    -- M3 NAVIGATION RAIL (Left Drawer / Sidebar)
    -- ==========================================================
    local sidebar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -47)
    sidebar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 51)
    sidebar:SetWidth(175)
    sidebar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    sidebar:SetBackdropColor(unpack(m3.surfaceContainerLow or { 0.06, 0.13, 0.15, 0.98 }))
    sidebar:SetBackdropBorderColor(unpack(m3.outlineVariant or { 0.22, 0.28, 0.31, 0.40 }))
    f.sidebar = sidebar

    -- Category Header Label in Nav Rail
    local navCatLabel = sidebar:CreateFontString(nil, "OVERLAY")
    navCatLabel:SetFont(fontBold, 10, "")
    navCatLabel:SetShadowOffset(0, 0)
    navCatLabel:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, -10)
    navCatLabel:SetTextColor(unpack(m3.outlineText or { 0.45, 0.50, 0.54, 1.0 }))
    navCatLabel:SetText(L["CATEGORY_MODULES"] or "MÓDULOS")

    -- Tab definitions using dedicated modern M3 PNG icons
    local tabDefs = {
        { id = "release",     icon = self:GetIconPath("m3_release.png"),       label = L["TAB_RELEASE"] or "Liberación" },
        { id = "raidflow",    icon = self:GetIconPath("m3_raidflow.png"),      label = L["TAB_RAIDFLOW"] or "Flujo de Raid" },
        { id = "automation",  icon = self:GetIconPath("m3_automation.png"),    label = L["TAB_AUTOMATION"] or "Automatización" },
        { id = "tooltips",    icon = self:GetIconPath("m3_loot.png"),          label = L["TAB_TOOLTIPS"] or "Tooltips & Botín" },
        { id = "performance", icon = self:GetIconPath("m3_performance.png"),   label = L["TAB_PERFORMANCE"] or "Rendimiento" },
        { id = "conflicts",   icon = self:GetIconPath("m3_compatibility.png"), label = L["TAB_CONFLICTS"] or "Compatibilidad" },
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
                    -- Active M3 Capsule Pill State
                    btn:SetBackdropColor(unpack(m3.primaryContainer or { 0.0, 0.28, 0.32, 0.95 }))
                    btn:SetBackdropBorderColor(unpack(m3.primary or { 0.0, 0.90, 1.0, 1.0 }))
                    if btn.icon then
                        btn.icon:SetVertexColor(unpack(m3.onPrimaryContainer or { 0.65, 0.96, 0.98, 1.0 }))
                        btn.icon:SetAlpha(1.0)
                    end
                    if btn.text then
                        btn.text:SetTextColor(1, 1, 1, 1)
                    end
                end
            else
                if page then page:Hide() end
                if btn and not btn.isSkinned then
                    -- Inactive Nav Item State
                    btn:SetBackdropColor(0, 0, 0, 0)
                    btn:SetBackdropBorderColor(0, 0, 0, 0)
                    if btn.icon then
                        btn.icon:SetVertexColor(1, 1, 1)
                        btn.icon:SetAlpha(0.70)
                    end
                    if btn.text then
                        btn.text:SetTextColor(unpack(m3.onSurfaceVariant or { 0.65, 0.70, 0.74, 1.0 }))
                    end
                end
            end
        end
    end
    f.ShowTab = ShowTab

    local btnHeight = 36
    local btnWidth = 163
    local btnSpacing = 4

    for i, def in ipairs(tabDefs) do
        local btn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        btn:SetSize(btnWidth, btnHeight)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 6, -26 - ((i - 1) * (btnHeight + btnSpacing)))
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })

        -- Dedicated Modern M3 Icon
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", btn, "LEFT", 10, 0)
        icon:SetTexture(def.icon)
        btn.icon = icon

        -- Category Label
        local btnText = btn:CreateFontString(nil, "OVERLAY")
        btnText:SetFont(fontSemiBold, 12, "")
        btnText:SetShadowOffset(0, 0)
        btnText:SetPoint("LEFT", icon, "RIGHT", 10, 0)
        btnText:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
        btnText:SetJustifyH("LEFT")
        btnText:SetWordWrap(false)
        btnText:SetText(def.label)
        btn.text = btnText

        btn:SetScript("OnClick", function()
            ShowTab(def.id)
        end)
        btn:SetScript("OnEnter", function(self)
            if activeTab ~= def.id and not self.isSkinned then
                self:SetBackdropColor(unpack(m3.surfaceContainerHighest or { 0.18, 0.18, 0.22, 1.0 }))
                self:SetBackdropBorderColor(unpack(m3.outlineVariant or { 0.16, 0.17, 0.21, 0.40 }))
                if self.icon then self.icon:SetAlpha(1.0) end
                if self.text then self.text:SetTextColor(1, 1, 1, 1) end
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if activeTab ~= def.id and not self.isSkinned then
                self:SetBackdropColor(0, 0, 0, 0)
                self:SetBackdropBorderColor(0, 0, 0, 0)
                if self.icon then self.icon:SetAlpha(0.70) end
                if self.text then self.text:SetTextColor(unpack(m3.onSurfaceVariant or { 0.62, 0.64, 0.70, 1.0 })) end
            end
        end)

        tabButtons[def.id] = btn

        -- Container page for this tab
        local page = CreateFrame("Frame", nil, f)
        page:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 12, 0)
        page:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 54)
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
    -- M3 BOTTOM ACTION BAR (50px High Tonal Bar)
    -- ==========================================================
    local bottomBar = f:CreateTexture(nil, "BACKGROUND")
    bottomBar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
    bottomBar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    bottomBar:SetHeight(50)
    bottomBar:SetColorTexture(unpack(m3.surfaceContainerLow or { 0.09, 0.09, 0.11, 0.98 }))

    -- Bottom Bar Top Divider
    local botDivider = f:CreateTexture(nil, "ARTWORK")
    botDivider:SetPoint("BOTTOMLEFT", bottomBar, "TOPLEFT", 0, 0)
    botDivider:SetPoint("BOTTOMRIGHT", bottomBar, "TOPRIGHT", 0, 0)
    botDivider:SetHeight(1)
    botDivider:SetColorTexture(unpack(m3.outlineVariant or { 0.16, 0.17, 0.21, 0.40 }))

    local bY = 10

    -- Button 1: Test Alert (M3 Filled Button - Primary)
    local btnTest = self:CreateM3Button(f, L["BTN_TEST"] or "Probar Alerta", "filled", 125, 30)
    btnTest:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, bY)
    btnTest:SetScript("OnClick", function()
        DQ.Alert:Trigger()
    end)

    -- Button 2: Simulate Death (M3 Tonal Button - Secondary)
    local btnSim = self:CreateM3Button(f, L["BTN_SIM"] or "Simular Muerte", "tonal", 125, 30)
    btnSim:SetPoint("LEFT", btnTest, "RIGHT", 10, 0)
    btnSim:SetScript("OnClick", function()
        if DQ.Detection and DQ.Detection.StartSimulation then
            DQ.Detection:StartSimulation()
        end
    end)

    -- Button 3: Mute Sound Toggle (M3 Dynamic Tonal / Error Button)
    local btnMute = self:CreateM3Button(f, "", "tonal", 155, 30)
    btnMute:SetPoint("LEFT", btnSim, "RIGHT", 10, 0)
    btnMute:SetScript("OnClick", function()
        local current = DQ.Config:Get("releaseGuard", "soundEnabled") ~= false
        local newVal = not current
        DQ.Config:Set("releaseGuard", "soundEnabled", newVal)
        DQ.UI:UpdateSoundControls()
    end)
    f.btnMute = btnMute

    -- Button 4: Close (M3 Outlined Button)
    local btnClose = self:CreateM3Button(f, L["BTN_CLOSE"] or "Cerrar", "outlined", 85, 30)
    btnClose:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, bY)
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
    local iconStr = self:GetSoundIcon(soundOn, 16)

    if configFrame.btnMute then
        local label = soundOn and (L["BTN_MUTE"] or "Mutear Sonido") or (L["BTN_UNMUTE"] or "Activar Sonido")
        configFrame.btnMute:SetButtonText(iconStr .. label)
        if configFrame.btnMute.SetVariant then
            configFrame.btnMute:SetVariant(soundOn and "tonal" or "error")
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

-- Shows a specific tab directly in the configuration panel
function DQ.UI:ShowTab(tabId)
    local panel = self:CreatePanel()
    if not panel:IsShown() then
        panel:Show()
    end
    if panel.ShowTab then
        panel.ShowTab(tabId)
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
