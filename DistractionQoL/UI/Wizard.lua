-- Wizard.lua
-- First-Time Setup Wizard for DistractionQoL
-- Provides a sleek, step-by-step interactive onboarding experience
-- Written with player-first UX, zero obscure jargon, and full multi-language support (ES / EN)

local addonName, DQ = ...

DQ.Wizard = {}

local wizardFrame = nil
local currentStep = 1
local totalSteps = 5

-- Safe print helper forwarding to DQ:Print
local function PrintMsg(msg)
    if DQ.Print then
        DQ:Print(msg)
    elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00e5ff[DistractionQoL]|r " .. tostring(msg))
    elseif print then
        print("|cff00e5ff[DistractionQoL]|r " .. tostring(msg))
    end
end

-- Flat button creation helper
local function CreateWizardButton(parent, text, w, h, isPrimary)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w or 120, h or 26)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })

    if isPrimary then
        btn:SetBackdropColor(0.0, 0.55, 0.70, 0.95)
        btn:SetBackdropBorderColor(0.0, 0.90, 1.0, 1)
    else
        btn:SetBackdropColor(0.12, 0.12, 0.16, 0.95)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    end

    local t = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    t:SetPoint("CENTER")
    t:SetText(text)
    btn.text = t

    btn:SetScript("OnEnter", function(self)
        if isPrimary then
            self:SetBackdropColor(0.0, 0.70, 0.85, 1)
            self:SetBackdropBorderColor(0.2, 1.0, 1.0, 1)
        else
            self:SetBackdropColor(0.20, 0.20, 0.26, 1)
            self:SetBackdropBorderColor(0.0, 0.85, 1.0, 0.8)
        end
        if self.text then self.text:SetTextColor(1, 1, 1, 1) end
    end)

    btn:SetScript("OnLeave", function(self)
        if isPrimary then
            self:SetBackdropColor(0.0, 0.55, 0.70, 0.95)
            self:SetBackdropBorderColor(0.0, 0.90, 1.0, 1)
        else
            self:SetBackdropColor(0.12, 0.12, 0.16, 0.95)
            self:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
        end
        if self.text then self.text:SetTextColor(0.9, 0.9, 0.9, 1) end
    end)

    return btn
end

-- Create step indicator bar
local function CreateStepBar(parent, count)
    local L = DQ.L or {}
    local stepBar = CreateFrame("Frame", nil, parent)
    stepBar:SetSize(600, 26)
    stepBar:SetPoint("TOP", parent, "TOP", 0, -38)

    local tabs = {}
    local labels = {
        L["WIZ_STEP_1"] or "1. Bienvenida",
        L["WIZ_STEP_2"] or "2. Anti-Liberar",
        L["WIZ_STEP_3"] or "3. Flujo Raid",
        L["WIZ_STEP_4"] or "4. Utilidades",
        L["WIZ_STEP_5"] or "5. Inventario",
    }

    local btnW = 114
    local gap = 6

    for i = 1, count do
        local btn = CreateFrame("Button", nil, stepBar, "BackdropTemplate")
        btn:SetSize(btnW, 24)
        btn:SetPoint("LEFT", stepBar, "LEFT", (i - 1) * (btnW + gap), 0)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        btn:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
        btn:SetBackdropBorderColor(0.20, 0.20, 0.25, 1)

        local t = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        t:SetPoint("CENTER")
        t:SetText(labels[i] or ("Paso " .. i))
        btn.text = t

        btn:SetScript("OnClick", function()
            DQ.Wizard:SetStep(i)
        end)

        tabs[i] = btn
    end

    stepBar.tabs = tabs
    return stepBar
end

-- Main Wizard Window Builder
local function BuildWizardWindow()
    if wizardFrame then return wizardFrame end

    local L = DQ.L or {}

    local f = CreateFrame("Frame", "DistractionQoLWizardFrame", UIParent, "BackdropTemplate")
    f:SetSize(660, 480)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    -- Modern flat obsidian backdrop
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    f:SetBackdropColor(0.06, 0.06, 0.09, 0.98)
    f:SetBackdropBorderColor(0.0, 0.85, 1.0, 0.9) -- Electric Cyan

    -- Header bar
    local headerBar = f:CreateTexture(nil, "BORDER")
    headerBar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    headerBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    headerBar:SetHeight(32)
    headerBar:SetColorTexture(0.03, 0.03, 0.05, 0.98)

    local headerAccent = f:CreateTexture(nil, "ARTWORK")
    headerAccent:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, 0)
    headerAccent:SetPoint("TOPRIGHT", headerBar, "BOTTOMRIGHT", 0, 0)
    headerAccent:SetHeight(1)
    headerAccent:SetColorTexture(0.0, 0.85, 1.0, 0.6)

    -- Header Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", headerBar, "LEFT", 14, 0)
    title:SetText(L["WIZ_TITLE"] or "|cff00e5ffDistractionQoL|r - |cffffffffAsistente de Configuración|r")

    -- Close Button (X) - clean standard ASCII, fully vector-styled
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("RIGHT", headerBar, "RIGHT", -6, 0)
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    local xText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    xText:SetPoint("CENTER", 0, 0)
    xText:SetText("|cffaaaaaaX|r")
    closeBtn.xText = xText
    closeBtn:HookScript("OnEnter", function(self) if self.xText then self.xText:SetText("|cffff3333X|r") end end)
    closeBtn:HookScript("OnLeave", function(self) if self.xText then self.xText:SetText("|cffaaaaaaX|r") end end)

    -- Step Indicator Bar
    local stepBar = CreateStepBar(f, totalSteps)
    f.stepBar = stepBar

    -- Content Body Container
    local contentBox = CreateFrame("Frame", nil, f, "BackdropTemplate")
    contentBox:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -72)
    contentBox:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 54)
    contentBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    contentBox:SetBackdropColor(0.08, 0.08, 0.12, 0.45)
    contentBox:SetBackdropBorderColor(0.18, 0.18, 0.22, 0.8)
    f.contentBox = contentBox

    -- Pages Container
    local pages = {}

    -- ==========================================================
    -- PAGE 1: BIENVENIDA & VENTAJAS
    -- ==========================================================
    local p1 = CreateFrame("Frame", nil, contentBox)
    p1:SetAllPoints()

    local p1Title = p1:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p1Title:SetPoint("TOPLEFT", p1, "TOPLEFT", 16, -16)
    local ver = (DQ.Util and DQ.Util.GetVersion and DQ.Util.GetVersion()) or "4.0.0"
    local rawTitle = L["WIZ_P1_TITLE"] or "Bienvenido a DistractionQoL v%s"
    local titleText = string.find(rawTitle, "%%s") and string.format(rawTitle, ver) or rawTitle
    p1Title:SetText("|cff00e5ff" .. titleText .. "|r")

    local p1Sub = p1:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p1Sub:SetPoint("TOPLEFT", p1Title, "BOTTOMLEFT", 0, -8)
    p1Sub:SetPoint("RIGHT", p1, "RIGHT", -16, 0)
    p1Sub:SetJustifyH("LEFT")
    p1Sub:SetWordWrap(true)
    p1Sub:SetText(L["WIZ_P1_DESC"] or "Herramientas esenciales de calidad de vida y preparación para jugadores de Míticas+ y Raid.")

    local p1Card = CreateFrame("Frame", nil, p1, "BackdropTemplate")
    p1Card:SetPoint("TOPLEFT", p1Sub, "BOTTOMLEFT", 0, -14)
    p1Card:SetPoint("BOTTOMRIGHT", p1, "BOTTOMRIGHT", -16, 16)
    p1Card:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    p1Card:SetBackdropColor(0.04, 0.04, 0.06, 0.85)
    p1Card:SetBackdropBorderColor(0.0, 0.85, 1.0, 0.4)

    local p1List = p1Card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    p1List:SetPoint("TOPLEFT", p1Card, "TOPLEFT", 14, -12)
    p1List:SetPoint("BOTTOMRIGHT", p1Card, "BOTTOMRIGHT", -14, 12)
    p1List:SetJustifyH("LEFT")
    p1List:SetJustifyV("TOP")
    p1List:SetWordWrap(true)

    local p1BoxTitle = L["WIZ_P1_BOX_TITLE"] or "Ventajas de DistractionQoL:"
    local p1Item1 = L["WIZ_P1_ITEM_1"] or "|cff00e5ff*|r Máximo rendimiento: Diseñado para mantener tus FPS al máximo, sin ralentizaciones en combate."
    local p1Item2 = L["WIZ_P1_ITEM_2"] or "|cff00e5ff*|r Sin bloqueos de interfaz: Funciona fluidamente sin congelar tus barras ni provocar errores en combate."
    local p1Item3 = L["WIZ_P1_ITEM_3"] or "|cff00e5ff*|r Compatibilidad total: Detecta y coexiste sin conflictos con EllesmereUI, ElvUI y NaowhUI."
    local p1Item4 = L["WIZ_P1_ITEM_4"] or "|cff00e5ff*|r Carga ultrarrápida: Ocupa una fracción mínima de memoria en comparación con suites pesadas."
    local p1Footer = L["WIZ_P1_FOOTER"] or "Haz clic en [Siguiente >] para comenzar a personalizar tu experiencia."

    p1List:SetText(string.format("|cff00ff00%s|r\n\n%s\n%s\n%s\n%s\n\n%s", p1BoxTitle, p1Item1, p1Item2, p1Item3, p1Item4, p1Footer))

    pages[1] = p1

    -- ==========================================================
    -- PAGE 2: RELEASE GUARD (ANTI-LIBERAR)
    -- ==========================================================
    local p2 = CreateFrame("Frame", nil, contentBox)
    p2:SetAllPoints()
    p2:Hide()

    local p2Title = p2:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p2Title:SetPoint("TOPLEFT", p2, "TOPLEFT", 16, -16)
    p2Title:SetText("|cff00e5ff" .. (L["WIZ_P2_TITLE"] or "Protección Anti-Liberar Espíritu") .. "|r")

    local p2Desc = p2:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p2Desc:SetPoint("TOPLEFT", p2Title, "BOTTOMLEFT", 0, -6)
    p2Desc:SetPoint("RIGHT", p2, "RIGHT", -16, 0)
    p2Desc:SetJustifyH("LEFT")
    p2Desc:SetWordWrap(true)
    p2Desc:SetText(L["WIZ_P2_DESC"] or "Evita liberar por error durante mazmorras o jefes de banda cuando aún quedan resurrecciones disponibles.")

    -- Comparison box
    local p2Box = CreateFrame("Frame", nil, p2, "BackdropTemplate")
    p2Box:SetPoint("TOPLEFT", p2Desc, "BOTTOMLEFT", 0, -12)
    p2Box:SetPoint("RIGHT", p2, "RIGHT", -16, 0)
    p2Box:SetHeight(120)
    p2Box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    p2Box:SetBackdropColor(0.04, 0.04, 0.07, 0.85)
    p2Box:SetBackdropBorderColor(0.0, 0.85, 1.0, 0.3)

    local p2BoxText = p2Box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    p2BoxText:SetPoint("TOPLEFT", p2Box, "TOPLEFT", 12, -10)
    p2BoxText:SetPoint("BOTTOMRIGHT", p2Box, "BOTTOMRIGHT", -12, 10)
    p2BoxText:SetJustifyH("LEFT")
    p2BoxText:SetWordWrap(true)

    local p2BoxTitle = L["WIZ_P2_BOX_TITLE"] or "¿Por qué nuestra protección es más práctica?"
    local p2Item1 = L["WIZ_P2_ITEM_1"] or "|cffffcc00*|r Liberación inmediata con SHIFT: Si el líder pide wipe, mantén presionado SHIFT y haz clic para liberar al instante."
    local p2Item2 = L["WIZ_P2_ITEM_2"] or "|cffffcc00*|r Sin esperas forzadas: No tienes que mantener presionado un botón por 1 segundo como en otros addons."
    local p2Item3 = L["WIZ_P2_ITEM_3"] or "|cffffcc00*|r Control por dificultad: Activo en M+ y Raid, pero libre e inactivo en mundo abierto."

    p2BoxText:SetText(string.format("|cffffcc00%s|r\n\n%s\n%s\n%s", p2BoxTitle, p2Item1, p2Item2, p2Item3))

    -- Checkboxes
    local cbDungeons = CreateFrame("CheckButton", "DQWizCBDungeons", p2, "UICheckButtonTemplate")
    cbDungeons:SetPoint("TOPLEFT", p2Box, "BOTTOMLEFT", 0, -12)
    cbDungeons.text = _G[cbDungeons:GetName() .. "Text"]
    cbDungeons.text:SetText(L["WIZ_P2_CB_DUNGEONS"] or "Activar en Mazmorras (M+ / Heroicas / Profundidades)")
    cbDungeons:SetChecked(DQ.Config:Get("releaseGuard", "dungeons"))
    cbDungeons:SetScript("OnClick", function(self)
        DQ.Config:Set("releaseGuard", "dungeons", self:GetChecked())
    end)

    local cbRaids = CreateFrame("CheckButton", "DQWizCBRaids", p2, "UICheckButtonTemplate")
    cbRaids:SetPoint("TOPLEFT", cbDungeons, "BOTTOMLEFT", 0, -4)
    cbRaids.text = _G[cbRaids:GetName() .. "Text"]
    cbRaids.text:SetText(L["WIZ_P2_CB_RAIDS"] or "Activar en Bandas (Mítico / Heroico / Normal)")
    cbRaids:SetChecked(DQ.Config:Get("releaseGuard", "raids", "enabled"))
    cbRaids:SetScript("OnClick", function(self)
        DQ.Config:Set("releaseGuard", "raids", "enabled", self:GetChecked())
    end)

    -- Sound row
    local soundRowLbl = p2:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    soundRowLbl:SetPoint("TOPLEFT", cbRaids, "BOTTOMLEFT", 4, -10)
    soundRowLbl:SetText(L["WIZ_P2_SOUND_LABEL"] or "Audio de Alerta:")

    local btnTestSound = CreateWizardButton(p2, L["WIZ_P2_BTN_TEST"] or "Probar Sonido", 120, 22)
    btnTestSound:SetPoint("LEFT", soundRowLbl, "RIGHT", 14, 0)
    btnTestSound:SetScript("OnClick", function()
        DQ.Alert:PlaySound()
    end)

    local soundHint = p2:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    soundHint:SetPoint("LEFT", btnTestSound, "RIGHT", 12, 0)
    local isEasterEgg = DQ.Alert and DQ.Alert.IsDistractionGuild and DQ.Alert:IsDistractionGuild()
    soundHint:SetText(isEasterEgg and "|cff00ff00[Easter Egg]|r Distraction (Quel'Thalas)" or "|cff00e5ffRaid Alert (Blizzard)|r")

    pages[2] = p2

    -- ==========================================================
    -- PAGE 3: PREPARACIÓN DE BANDA & ALERTAS
    -- ==========================================================
    local p3 = CreateFrame("Frame", nil, contentBox)
    p3:SetAllPoints()
    p3:Hide()

    local p3Title = p3:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p3Title:SetPoint("TOPLEFT", p3, "TOPLEFT", 16, -16)
    p3Title:SetText("|cff00e5ff" .. (L["WIZ_P3_TITLE"] or "Flujo de Banda y Alertas") .. "|r")

    local p3Desc = p3:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p3Desc:SetPoint("TOPLEFT", p3Title, "BOTTOMLEFT", 0, -6)
    p3Desc:SetPoint("RIGHT", p3, "RIGHT", -16, 0)
    p3Desc:SetJustifyH("LEFT")
    p3Desc:SetWordWrap(true)
    p3Desc:SetText(L["WIZ_P3_DESC"] or "Avisos visuales y sonoros para no perder llamadas importantes, incluso si tienes el juego en segundo plano:")

    local cbTaskbar = CreateFrame("CheckButton", "DQWizCBTaskbar", p3, "UICheckButtonTemplate")
    cbTaskbar:SetPoint("TOPLEFT", p3Desc, "BOTTOMLEFT", 0, -14)
    cbTaskbar.text = _G[cbTaskbar:GetName() .. "Text"]
    cbTaskbar.text:SetText(L["WIZ_P3_CB_TASKBAR"] or "Hacer parpadear la ventana en la barra de tareas al iniciar Ready Check o Pull Timers")
    cbTaskbar:SetChecked(DQ.Config:Get("raidFlow", "flashTaskbar"))
    cbTaskbar:SetScript("OnClick", function(self)
        DQ.Config:Set("raidFlow", "flashTaskbar", self:GetChecked())
    end)

    local cbReadyPing = CreateFrame("CheckButton", "DQWizCBReadyPing", p3, "UICheckButtonTemplate")
    cbReadyPing:SetPoint("TOPLEFT", cbTaskbar, "BOTTOMLEFT", 0, -6)
    cbReadyPing.text = _G[cbReadyPing:GetName() .. "Text"]
    cbReadyPing.text:SetText(L["WIZ_P3_CB_SOUND"] or "Alerta sonora prioritaria en Ready Check (audible con el juego minimizado)")
    cbReadyPing:SetChecked(DQ.Config:Get("raidFlow", "readyCheckSound"))
    cbReadyPing:SetScript("OnClick", function(self)
        DQ.Config:Set("raidFlow", "readyCheckSound", self:GetChecked())
    end)

    local cbConsumables = CreateFrame("CheckButton", "DQWizCBConsumables", p3, "UICheckButtonTemplate")
    cbConsumables:SetPoint("TOPLEFT", cbReadyPing, "BOTTOMLEFT", 0, -6)
    cbConsumables.text = _G[cbConsumables:GetName() .. "Text"]
    cbConsumables.text:SetText(L["WIZ_P3_CB_CONSUMABLES"] or "Avisar en chat si te falta comida, frasco, runa o mejora de arma antes del combate")
    cbConsumables:SetChecked(DQ.Config:Get("raidFlow", "checkConsumables"))
    cbConsumables:SetScript("OnClick", function(self)
        DQ.Config:Set("raidFlow", "checkConsumables", self:GetChecked())
    end)

    local cbExpiring = CreateFrame("CheckButton", "DQWizCBExpiring", p3, "UICheckButtonTemplate")
    cbExpiring:SetPoint("TOPLEFT", cbConsumables, "BOTTOMLEFT", 0, -6)
    cbExpiring.text = _G[cbExpiring:GetName() .. "Text"]
    cbExpiring.text:SetText(L["WIZ_P3_CB_EXPIRING"] or "Aviso de consumibles por expirar: Alerta si te quedan menos de 5 minutos de comida o frasco")
    cbExpiring:SetChecked(DQ.Config:Get("raidFlow", "warnExpiringConsumables"))
    cbExpiring:SetScript("OnClick", function(self)
        DQ.Config:Set("raidFlow", "warnExpiringConsumables", self:GetChecked())
    end)

    local cbLfg = CreateFrame("CheckButton", "DQWizCBLFG", p3, "UICheckButtonTemplate")
    cbLfg:SetPoint("TOPLEFT", cbExpiring, "BOTTOMLEFT", 0, -6)
    cbLfg.text = _G[cbLfg:GetName() .. "Text"]
    cbLfg.text:SetText(L["WIZ_P3_CB_LFG"] or "Alerta de buscador (LFG): Sonido y aviso en barra de tareas al encontrar grupo")
    cbLfg:SetChecked(DQ.Config:Get("raidFlow", "lfgAlert"))
    cbLfg:SetScript("OnClick", function(self)
        DQ.Config:Set("raidFlow", "lfgAlert", self:GetChecked())
    end)

    local p3Note = p3:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    p3Note:SetPoint("TOPLEFT", cbLfg, "BOTTOMLEFT", 4, -10)
    p3Note:SetPoint("RIGHT", p3, "RIGHT", -16, 0)
    p3Note:SetJustifyH("LEFT")
    p3Note:SetWordWrap(true)
    p3Note:SetText(L["WIZ_P3_NOTE"] or "* Todas las revisiones se ejecutan solo en momentos clave, con cero consumo en combate.")

    pages[3] = p3

    -- ==========================================================
    -- PAGE 4: AUTOMATIZACIONES
    -- ==========================================================
    local p4 = CreateFrame("Frame", nil, contentBox)
    p4:SetAllPoints()
    p4:Hide()

    local p4Title = p4:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p4Title:SetPoint("TOPLEFT", p4, "TOPLEFT", 16, -16)
    p4Title:SetText("|cff00e5ff" .. (L["WIZ_P4_TITLE"] or "Automatizaciones de Calidad de Vida") .. "|r")

    local p4Desc = p4:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p4Desc:SetPoint("TOPLEFT", p4Title, "BOTTOMLEFT", 0, -6)
    p4Desc:SetPoint("RIGHT", p4, "RIGHT", -16, 0)
    p4Desc:SetJustifyH("LEFT")
    p4Desc:SetWordWrap(true)
    p4Desc:SetText(L["WIZ_P4_DESC"] or "Ahorra tiempo en tareas mecánicas y repetitivas sin interferir con tus otros addons:")

    local autoItems = {
        { key = "autoRepair", label = L["WIZ_P4_REPAIR"] or "Reparación automática de equipo al hablar con un mercader" },
        { key = "guildRepair", label = L["WIZ_P4_GUILD_REPAIR"] or "Priorizar fondos de hermandad para reparaciones" },
        { key = "autoSellJunk", label = L["WIZ_P4_SELL_JUNK"] or "Venta automática de basura gris con un mercader" },
        { key = "fastLoot", label = L["WIZ_P4_FAST_LOOT"] or "Despojo rápido instantáneo al saquear (Fast Loot)" },
        { key = "autoSkipCinematics", label = L["WIZ_P4_MOVIES"] or "Saltar automáticamente cinemáticas y videos ya vistos" },
        { key = "blockDuels", label = L["WIZ_P4_DUELS"] or "Bloquear invitaciones a duelo dentro de mazmorras y bandas" },
    }

    local lastAnchor = p4Desc
    for i, item in ipairs(autoItems) do
        local cb = CreateFrame("CheckButton", "DQWizCBAuto" .. i, p4, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, (i == 1) and -10 or -3)
        cb.text = _G[cb:GetName() .. "Text"]
        cb.text:SetText(item.label)
        cb:SetChecked(DQ.Config:Get("automation", item.key))
        cb:SetScript("OnClick", function(self)
            DQ.Config:Set("automation", item.key, self:GetChecked())
            if DQ.ConflictResolver then
                DQ.ConflictResolver:SetChoice(item.key, self:GetChecked() and "DistractionQoL" or "External", true)
            end
        end)
        lastAnchor = cb
    end

    -- M+ Auto Keystone Slotter
    local cbKey = CreateFrame("CheckButton", "DQWizCBAutoKey", p4, "UICheckButtonTemplate")
    cbKey:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -3)
    cbKey.text = _G[cbKey:GetName() .. "Text"]
    cbKey.text:SetText(L["WIZ_P4_KEYSTONE"] or "M+ Auto-Piedra: Colocar automáticamente la llave en el pedestal")
    cbKey:SetChecked(DQ.Config:Get("mythicPlus", "autoSlot"))
    cbKey:SetScript("OnClick", function(self)
        DQ.Config:Set("mythicPlus", "autoSlot", self:GetChecked())
    end)

    pages[4] = p4

    -- ==========================================================
    -- PAGE 5: INVENTARIO & ORDEN INTELIGENTE
    -- ==========================================================
    local p5 = CreateFrame("Frame", nil, contentBox)
    p5:SetAllPoints()
    p5:Hide()

    local p5Title = p5:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p5Title:SetPoint("TOPLEFT", p5, "TOPLEFT", 16, -16)
    p5Title:SetText("|cff00e5ff" .. (L["WIZ_P5_TITLE"] or "Organización Inteligente de Bolsas") .. "|r")

    local p5Desc = p5:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p5Desc:SetPoint("TOPLEFT", p5Title, "BOTTOMLEFT", 0, -6)
    p5Desc:SetPoint("RIGHT", p5, "RIGHT", -16, 0)
    p5Desc:SetJustifyH("LEFT")
    p5Desc:SetWordWrap(true)
    p5Desc:SetText(L["WIZ_P5_DESC"] or "Mantén tu inventario organizado de forma clara y accesible:")

    local p5Box = CreateFrame("Frame", nil, p5, "BackdropTemplate")
    p5Box:SetPoint("TOPLEFT", p5Desc, "BOTTOMLEFT", 0, -12)
    p5Box:SetPoint("RIGHT", p5, "RIGHT", -16, 0)
    p5Box:SetHeight(110)
    p5Box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    p5Box:SetBackdropColor(0.04, 0.04, 0.07, 0.85)
    p5Box:SetBackdropBorderColor(0.0, 0.85, 1.0, 0.3)

    local p5BoxText = p5Box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    p5BoxText:SetPoint("TOPLEFT", p5Box, "TOPLEFT", 12, -10)
    p5BoxText:SetPoint("BOTTOMRIGHT", p5Box, "BOTTOMRIGHT", -12, 10)
    p5BoxText:SetJustifyH("LEFT")
    p5BoxText:SetWordWrap(true)

    local p5BoxTitle = L["WIZ_P5_BOX_TITLE"] or "¿Cómo organiza DistractionQoL tus bolsas?"
    local p5Explanation = L["WIZ_P5_EXPLANATION"] or "1. Mueve materiales de artesanía a tu Bolsa de Componentes.\n2. Los materiales sobrantes se colocan en la parte superior.\n3. Tu equipo y objetos activos se agrupan ordenados en la parte inferior, dejando espacio libre en el centro."

    p5BoxText:SetText(string.format("|cffffcc00%s|r\n\n%s", p5BoxTitle, p5Explanation))

    local cbBagBtn = CreateFrame("CheckButton", "DQWizCBBagBtn", p5, "UICheckButtonTemplate")
    cbBagBtn:SetPoint("TOPLEFT", p5Box, "BOTTOMLEFT", 0, -12)
    cbBagBtn.text = _G[cbBagBtn:GetName() .. "Text"]
    cbBagBtn.text:SetText(L["WIZ_P5_CB_BAG_BTN"] or "Mostrar botón de Orden Inverso en las bolsas de Blizzard")
    cbBagBtn:SetChecked(DQ.Config:Get("automation", "bagSortButton"))
    cbBagBtn:SetScript("OnClick", function(self)
        DQ.Config:Set("automation", "bagSortButton", self:GetChecked())
        if DQ.BagSort and DQ.BagSort.UpdateBagButtonVisibility then
            DQ.BagSort:UpdateBagButtonVisibility()
        end
    end)

    local cbOverrideEUI = CreateFrame("CheckButton", "DQWizCBOverrideEUI", p5, "UICheckButtonTemplate")
    cbOverrideEUI:SetPoint("TOPLEFT", cbBagBtn, "BOTTOMLEFT", 0, -6)
    cbOverrideEUI.text = _G[cbOverrideEUI:GetName() .. "Text"]
    cbOverrideEUI.text:SetText(L["WIZ_P5_CB_OVERRIDE_EUI"] or "EllesmereUI: Reemplazar su botón de ordenar con el de DistractionQoL")
    cbOverrideEUI:SetChecked(DQ.Config:Get("automation", "overrideEllesmereSort"))
    cbOverrideEUI:SetScript("OnClick", function(self)
        DQ.Config:Set("automation", "overrideEllesmereSort", self:GetChecked())
        if DQ.BagSort and DQ.BagSort.HookEllesmereBags then
            DQ.BagSort:HookEllesmereBags()
        end
    end)

    pages[5] = p5

    f.pages = pages

    -- ==========================================================
    -- BOTTOM ACTION BAR
    -- ==========================================================
    local btnPrev = CreateWizardButton(f, L["BTN_PREV"] or "< Anterior", 110, 28)
    btnPrev:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 14)
    btnPrev:SetScript("OnClick", function()
        DQ.Wizard:SetStep(currentStep - 1)
    end)
    f.btnPrev = btnPrev

    local btnSkip = CreateWizardButton(f, L["BTN_CLOSE"] or "Cerrar", 90, 28)
    btnSkip:SetPoint("LEFT", btnPrev, "RIGHT", 8, 0)
    btnSkip:SetScript("OnClick", function()
        f:Hide()
    end)
    f.btnSkip = btnSkip

    local btnNext = CreateWizardButton(f, L["BTN_NEXT"] or "Siguiente >", 150, 28, true)
    btnNext:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 14)
    btnNext:SetScript("OnClick", function()
        if currentStep < totalSteps then
            DQ.Wizard:SetStep(currentStep + 1)
        else
            DQ.Wizard:Complete()
        end
    end)
    f.btnNext = btnNext

    wizardFrame = f
    return f
end

-- Sets active wizard step
function DQ.Wizard:SetStep(step)
    if step < 1 then step = 1 end
    if step > totalSteps then step = totalSteps end
    currentStep = step

    local f = BuildWizardWindow()
    local L = DQ.L or {}

    -- Update pages visibility
    for i, page in ipairs(f.pages) do
        if i == step then
            page:Show()
        else
            page:Hide()
        end
    end

    -- Update step tab buttons
    for i, tab in ipairs(f.stepBar.tabs) do
        if i == step then
            tab:SetBackdropColor(0.0, 0.45, 0.60, 0.95)
            tab:SetBackdropBorderColor(0.0, 0.90, 1.0, 1)
            tab.text:SetTextColor(1, 1, 1, 1)
        else
            tab:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
            tab:SetBackdropBorderColor(0.20, 0.20, 0.25, 1)
            tab.text:SetTextColor(0.70, 0.70, 0.75, 1)
        end
    end

    -- Update Prev/Next buttons
    f.btnPrev:SetEnabled(step > 1)
    f.btnPrev:SetAlpha(step > 1 and 1 or 0.4)

    if step == totalSteps then
        f.btnNext.text:SetText(L["BTN_FINISH"] or "Guardar y Finalizar")
    else
        f.btnNext.text:SetText(L["BTN_NEXT"] or "Siguiente >")
    end
end

-- Completes wizard and marks installerVersion as finished
function DQ.Wizard:Complete()
    if not DistractionQoLDB then DistractionQoLDB = {} end
    DistractionQoLDB.installerVersion = 3

    if wizardFrame then
        wizardFrame:Hide()
    end

    local L = DQ.L or {}
    PrintMsg(L["MSG_WIZARD_COMPLETE"] or "Initial setup complete! You can reopen this wizard at any time with /qol install.")
end

-- Opens the wizard at step 1
function DQ.Wizard:Open()
    local f = BuildWizardWindow()
    self:SetStep(1)
    f:Show()
end

-- Check if installer needs to be shown on login
function DQ.Wizard:CheckAutoRun()
    local dbVer = (DistractionQoLDB and DistractionQoLDB.installerVersion) or 0
    if dbVer < 3 then
        -- Delay 1.5 seconds so all external addon DBs settle cleanly
        C_Timer.After(1.5, function()
            DQ.Wizard:Open()
        end)
    end
end
