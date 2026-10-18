-- Wizard.lua
-- First-Time Setup Wizard for DistractionQoL
-- Provides a sleek, step-by-step interactive onboarding experience
-- Detects existing addons (EllesmereUI, NaowhUI, ElvUI) and resolves conflicts upfront

local addonName, DQ = ...

DQ.Wizard = {}

local wizardFrame = nil
local currentStep = 1
local totalSteps = 5

-- Safe print helper
local function PrintMsg(msg)
    local formatted = "|cff00e5ff[DistractionQoL]|r " .. tostring(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(formatted)
    elseif print then
        print(formatted)
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
    local stepBar = CreateFrame("Frame", nil, parent)
    stepBar:SetSize(600, 26)
    stepBar:SetPoint("TOP", parent, "TOP", 0, -38)

    local tabs = {}
    local labels = {
        "1. Bienvenida",
        "2. Anti-Liberar",
        "3. Flujo Raid",
        "4. Automatizaciones",
        "5. Inventario",
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
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalMedium")
    title:SetPoint("LEFT", headerBar, "LEFT", 14, 0)
    title:SetText("|cff00e5ffDistractionQoL|r — |cffffffffAsistente de Configuración Inicial|r")

    -- Close Button (X)
    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("RIGHT", headerBar, "RIGHT", -6, 0)
    closeBtn:SetNormalFontObject("GameFontNormalLarge")
    closeBtn:SetHighlightFontObject("GameFontHighlightLarge")
    closeBtn:SetText("×")
    closeBtn:SetScript("OnClick", function() f:Hide() end)

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
    -- PAGE 1: BIENVENIDA & FILOSOFÍA
    -- ==========================================================
    local p1 = CreateFrame("Frame", nil, contentBox)
    p1:SetAllPoints()

    local p1Title = p1:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p1Title:SetPoint("TOPLEFT", p1, "TOPLEFT", 16, -16)
    p1Title:SetText("|cff00e5ffBienvenido a DistractionQoL v2.1|r")

    local p1Sub = p1:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p1Sub:SetPoint("TOPLEFT", p1Title, "BOTTOMLEFT", 0, -8)
    p1Sub:SetPoint("RIGHT", p1, "RIGHT", -16, 0)
    p1Sub:SetJustifyH("LEFT")
    p1Sub:SetWordWrap(true)
    p1Sub:SetText("Un kit de utilidades de alto rendimiento y anti-distracción diseñado específicamente para jugadores de |cffffcc00Raid Mítica|r y |cffffcc00Míticas+|r.\n\nEste asistente te guiará en menos de 1 minuto para activar las funciones que necesitas y configurar la compatibilidad con otros addons instalados en tu interfaz.")

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
    p1List:SetText("|cff00ff00⚡ Principios de Ingeniería Limpia de DistractionQoL:|r\n\n" ..
        "• |cffffffff0% de impacto en FPS:|r Todo es 100% conducido por eventos. Cero bucles OnUpdate en combate.\n" ..
        "• |cffffffffZero-Taint:|r Compatible y seguro con el motor de WoW 12.1.5 (Midnight).\n" ..
        "• |cffffffffIntegración Nativa:|r Coexiste fluidamente con EllesmereUI, NaowhUI y ElvUI sin pisar sus opciones.\n" ..
        "• |cffffffffUltraligero:|r Menos de 100 KB de memoria total en uso.\n\n" ..
        "Haz clic en |cff00e5ff[Siguiente ►]|r para comenzar a personalizar tu experiencia.")

    pages[1] = p1

    -- ==========================================================
    -- PAGE 2: RELEASE GUARD (ANTI-LIBERAR)
    -- ==========================================================
    local p2 = CreateFrame("Frame", nil, contentBox)
    p2:SetAllPoints()
    p2:Hide()

    local p2Title = p2:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p2Title:SetPoint("TOPLEFT", p2, "TOPLEFT", 16, -16)
    p2Title:SetText("|cff00e5ffProtección Anti-Liberar Espíritu (Release Guard)|r")

    local p2Desc = p2:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p2Desc:SetPoint("TOPLEFT", p2Title, "BOTTOMLEFT", 0, -6)
    p2Desc:SetPoint("RIGHT", p2, "RIGHT", -16, 0)
    p2Desc:SetJustifyH("LEFT")
    p2Desc:SetWordWrap(true)
    p2Desc:SetText("Evita clics accidentales en el botón de liberar espíritu durante mazmorras Míticas y encuentros de Raid, evitando perder Battle Rezzes valiosos.")

    -- Comparison box with NaowhUI / Blizzard
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
    p2BoxText:SetText("|cffffcc00¿Por qué la protección de DistractionQoL es superior?|r\n" ..
        "• |cffffffffBypass Instantáneo:|r Mantén |cffffcc00SHIFT|r y haz clic para liberar de inmediato cuando el líder ordene wipe (sin esperar segundos).\n" ..
        "• |cffffffffFiltro por Dificultad:|r Activo en M+ y Raid (Mítico/Heroico/Normal), pero libre en mundo abierto.\n" ..
        "• |cffffffffNaowhUI vs DQOL:|r Naowh te obliga a esperar 1.0s manteniendo presionado el botón. DQOL es instantáneo con SHIFT.")

    -- Checkboxes
    local cbDungeons = CreateFrame("CheckButton", "DQWizCBDungeons", p2, "UICheckButtonTemplate")
    cbDungeons:SetPoint("TOPLEFT", p2Box, "BOTTOMLEFT", 0, -12)
    cbDungeons.text = _G[cbDungeons:GetName() .. "Text"]
    cbDungeons.text:SetText("Activar en Mazmorras (M+ / Heroicas)")
    cbDungeons:SetChecked(DQ.Config:Get("releaseGuard", "dungeons"))
    cbDungeons:SetScript("OnClick", function(self)
        DQ.Config:Set("releaseGuard", "dungeons", self:GetChecked())
    end)

    local cbRaids = CreateFrame("CheckButton", "DQWizCBRaids", p2, "UICheckButtonTemplate")
    cbRaids:SetPoint("TOPLEFT", cbDungeons, "BOTTOMLEFT", 0, -4)
    cbRaids.text = _G[cbRaids:GetName() .. "Text"]
    cbRaids.text:SetText("Activar en Bandas (Mítico / Heroico / Normal)")
    cbRaids:SetChecked(DQ.Config:Get("releaseGuard", "raids", "enabled"))
    cbRaids:SetScript("OnClick", function(self)
        DQ.Config:Set("releaseGuard", "raids", "enabled", self:GetChecked())
    end)

    -- Sound row
    local soundRowLbl = p2:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    soundRowLbl:SetPoint("TOPLEFT", cbRaids, "BOTTOMLEFT", 4, -10)
    soundRowLbl:SetText("Audio de Alerta:")

    local btnTestSound = CreateWizardButton(p2, "▶ Probar Audio", 120, 22)
    btnTestSound:SetPoint("LEFT", soundRowLbl, "RIGHT", 14, 0)
    btnTestSound:SetScript("OnClick", function()
        DQ.Alert:PlaySound()
    end)

    local soundHint = p2:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    soundHint:SetPoint("LEFT", btnTestSound, "RIGHT", 12, 0)
    soundHint:SetText(DQ.Alert:IsDistractionGuild() and "|cff00ff00[Easter Egg Activo]|r Hermandad Distraction de Quel'Thalas." or "Alarma táctica limpia de WoW activa.")

    pages[2] = p2

    -- ==========================================================
    -- PAGE 3: FLUJO DE RAID & ANTI-DISTRACCIÓN
    -- ==========================================================
    local p3 = CreateFrame("Frame", nil, contentBox)
    p3:SetAllPoints()
    p3:Hide()

    local p3Title = p3:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p3Title:SetPoint("TOPLEFT", p3, "TOPLEFT", 16, -16)
    p3Title:SetText("|cff00e5ffFlujo de Raid & Anti-Distracción|r")

    local p3Desc = p3:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p3Desc:SetPoint("TOPLEFT", p3Title, "BOTTOMLEFT", 0, -6)
    p3Desc:SetPoint("RIGHT", p3, "RIGHT", -16, 0)
    p3Desc:SetJustifyH("LEFT")
    p3Desc:SetWordWrap(true)
    p3Desc:SetText("Funcionalidades diseñadas para jugadores que usan una segunda pantalla o minimizan el juego mientras se organiza la raid:")

    local cbTaskbar = CreateFrame("CheckButton", "DQWizCBTaskbar", p3, "UICheckButtonTemplate")
    cbTaskbar:SetPoint("TOPLEFT", p3Desc, "BOTTOMLEFT", 0, -14)
    cbTaskbar.text = _G[cbTaskbar:GetName() .. "Text"]
    cbTaskbar.text:SetText("Parpadear icono de Windows en la barra de tareas al Ready Check y Pull Timers (DBM/BigWigs)")
    cbTaskbar:SetChecked(DQ.Config:Get("raidFlow", "flashTaskbar"))
    cbTaskbar:SetScript("OnClick", function(self)
        DQ.Config:Set("raidFlow", "flashTaskbar", self:GetChecked())
    end)

    local cbReadyPing = CreateFrame("CheckButton", "DQWizCBReadyPing", p3, "UICheckButtonTemplate")
    cbReadyPing:SetPoint("TOPLEFT", cbTaskbar, "BOTTOMLEFT", 0, -8)
    cbReadyPing.text = _G[cbReadyPing:GetName() .. "Text"]
    cbReadyPing.text:SetText("Reproducir ping sonoro por el canal Maestro al Ready Check (incluso si el juego está en segundo plano)")
    cbReadyPing:SetChecked(DQ.Config:Get("raidFlow", "readyCheckSound"))
    cbReadyPing:SetScript("OnClick", function(self)
        DQ.Config:Set("raidFlow", "readyCheckSound", self:GetChecked())
    end)

    local cbConsumables = CreateFrame("CheckButton", "DQWizCBConsumables", p3, "UICheckButtonTemplate")
    cbConsumables:SetPoint("TOPLEFT", cbReadyPing, "BOTTOMLEFT", 0, -8)
    cbConsumables.text = _G[cbConsumables:GetName() .. "Text"]
    cbConsumables.text:SetText("Auditoría de Consumibles Pre-Pull: Avisa en chat si te falta Comida, Frasco, Runa o Aceite de arma")
    cbConsumables:SetChecked(DQ.Config:Get("raidFlow", "checkConsumables"))
    cbConsumables:SetScript("OnClick", function(self)
        DQ.Config:Set("raidFlow", "checkConsumables", self:GetChecked())
    end)

    local p3Note = p3:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    p3Note:SetPoint("TOPLEFT", cbConsumables, "BOTTOMLEFT", 4, -14)
    p3Note:SetPoint("RIGHT", p3, "RIGHT", -16, 0)
    p3Note:SetJustifyH("LEFT")
    p3Note:SetWordWrap(true)
    p3Note:SetText("|cff00e5ff* Nota de rendimiento:|r El chequeo de consumibles se realiza únicamente en el milisegundo exacto en que se inicia el Ready Check. Consume 0% de CPU durante el combate.")

    pages[3] = p3

    -- ==========================================================
    -- PAGE 4: AUTOMATIZACIONES & CONFLICT RESOLUTION
    -- ==========================================================
    local p4 = CreateFrame("Frame", nil, contentBox)
    p4:SetAllPoints()
    p4:Hide()

    local p4Title = p4:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p4Title:SetPoint("TOPLEFT", p4, "TOPLEFT", 16, -16)
    p4Title:SetText("|cff00e5ffAutomatizaciones de Calidad de Vida (QoL)|r")

    local p4Desc = p4:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p4Desc:SetPoint("TOPLEFT", p4Title, "BOTTOMLEFT", 0, -6)
    p4Desc:SetPoint("RIGHT", p4, "RIGHT", -16, 0)
    p4Desc:SetJustifyH("LEFT")
    p4Desc:SetWordWrap(true)
    p4Desc:SetText("DistractionQoL resuelve automáticamente los conflictos si tienes EllesmereUI o ElvUI instalados. Elige qué funciones deseas que controle DQOL:")

    local autoItems = {
        { key = "autoRepair", label = "Auto-Reparación de equipo en mercaderes", default = true },
        { key = "guildRepair", label = "Priorizar fondos de hermandad para reparaciones", default = true },
        { key = "autoSellJunk", label = "Auto-Venta instantánea de basura gris al hablar con mercader", default = true },
        { key = "fastLoot", label = "Despojo rápido instantáneo a 0ms (Fast Loot)", default = true },
        { key = "autoSkipCinematics", label = "Saltar automáticamente cinemáticas y movies ya vistas", default = true },
        { key = "blockDuels", label = "Bloquear invitaciones a duelos dentro de mazmorras/raid", default = true },
    }

    local lastAnchor = p4Desc
    for i, item in ipairs(autoItems) do
        local cb = CreateFrame("CheckButton", "DQWizCBAuto" .. i, p4, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, (i == 1) and -10 or -4)
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

    pages[4] = p4

    -- ==========================================================
    -- PAGE 5: INVENTARIO & ORDEN INVERSO
    -- ==========================================================
    local p5 = CreateFrame("Frame", nil, contentBox)
    p5:SetAllPoints()
    p5:Hide()

    local p5Title = p5:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p5Title:SetPoint("TOPLEFT", p5, "TOPLEFT", 16, -16)
    p5Title:SetText("|cff00e5ffOrdenamiento Inverso & Alijo de Reagentes|r")

    local p5Desc = p5:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p5Desc:SetPoint("TOPLEFT", p5Title, "BOTTOMLEFT", 0, -6)
    p5Desc:SetPoint("RIGHT", p5, "RIGHT", -16, 0)
    p5Desc:SetJustifyH("LEFT")
    p5Desc:SetWordWrap(true)
    p5Desc:SetText("Una de las funciones más queridas: organiza tu inventario de forma lógica sin mezclar materiales con tu equipo:")

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
    p5BoxText:SetText("|cffffcc00¿Cómo opera el Orden Inverso de DistractionQoL?|r\n" ..
        "1. Detecta todos los materiales de artesanía/profesión y los guarda en la |cff00e5ffBolsa de Reagentes (Bolsa 5)|r.\n" ..
        "2. Si sobran materiales, los coloca |cffffcc00arriba del todo|r en las bolsas normales.\n" ..
        "3. El resto de objetos (equipo, pociones, comida) se agrupan ordenados |cff00ff00abajo del todo|r, dejando el centro libre.")

    local cbBagBtn = CreateFrame("CheckButton", "DQWizCBBagBtn", p5, "UICheckButtonTemplate")
    cbBagBtn:SetPoint("TOPLEFT", p5Box, "BOTTOMLEFT", 0, -12)
    cbBagBtn.text = _G[cbBagBtn:GetName() .. "Text"]
    cbBagBtn.text:SetText("Mostrar botón de Orden Inverso en la cabecera de las bolsas de Blizzard")
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
    cbOverrideEUI.text:SetText("EllesmereUI: Reemplazar su botón de ordenar bolsas con el Orden Inverso de DQOL")
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
    local btnPrev = CreateWizardButton(f, "◄ Anterior", 110, 28)
    btnPrev:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 14)
    btnPrev:SetScript("OnClick", function()
        DQ.Wizard:SetStep(currentStep - 1)
    end)
    f.btnPrev = btnPrev

    local btnSkip = CreateWizardButton(f, "Cerrar", 90, 28)
    btnSkip:SetPoint("LEFT", btnPrev, "RIGHT", 8, 0)
    btnSkip:SetScript("OnClick", function()
        f:Hide()
    end)
    f.btnSkip = btnSkip

    local btnNext = CreateWizardButton(f, "Siguiente ►", 140, 28, true)
    btnNext:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 14)
    btnNext:SetScript("OnClick", function()
        if currentStep < totalSteps then
            DQ.Wizard:SetStep(currentStep + 1)
        else
            -- Finish installer
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
        f.btnNext.text:SetText("¡Guardar y Finalizar! ✔")
    else
        f.btnNext.text:SetText("Siguiente ►")
    end
end

-- Completes wizard and marks installerVersion as finished
function DQ.Wizard:Complete()
    if not DistractionQoLDB then DistractionQoLDB = {} end
    DistractionQoLDB.installerVersion = 2

    if wizardFrame then
        wizardFrame:Hide()
    end

    local L = DQ.L or {}
    PrintMsg(L["MSG_WIZARD_COMPLETE"] or "¡Configuración completada con éxito! Puedes reabrir este asistente en cualquier momento escribiendo |cffffcc00/qol install|r.")
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
    if dbVer < 2 then
        -- Delay 1.5 seconds so all external addon DBs settle cleanly
        C_Timer.After(1.5, function()
            DQ.Wizard:Open()
        end)
    end
end
