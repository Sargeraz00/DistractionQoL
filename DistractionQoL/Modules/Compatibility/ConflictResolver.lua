-- ConflictResolver.lua
-- Intelligent feature conflict detection and prompt resolver for DistractionQoL
-- Detects overlapping functionality with EllesmereUI and ElvUI
-- Prompts user with a sleek obsidian modal and "Don't ask again" persistence

local addonName, DQ = ...

DQ.ConflictResolver = {}

-- Safe print helper
local function PrintMsg(msg)
    local formatted = "|cff00e5ff[DistractionQoL]|r " .. tostring(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(formatted)
    elseif print then
        print(formatted)
    end
end

-- ==========================================================
-- CONFLICT DEFINITIONS REGISTRY
-- ==========================================================
local CONFLICT_DEFINITIONS = {
    autoRepair = {
        name = "Auto-Reparación de Equipo",
        nameEn = "Auto-Repair Gear",
        icon = "Interface\\Icons\\Trade_BlackSmithing",
        detectConflict = function()
            -- 1. EllesmereUI check
            if C_AddOns and (C_AddOns.IsAddOnLoaded("EllesmereUIQoL") or C_AddOns.IsAddOnLoaded("EllesmereUI")) then
                return "EllesmereUI"
            end
            -- 2. ElvUI check
            if _G["ElvUI"] then
                local E = _G["ElvUI"][1]
                if E and E.db and E.db.general and E.db.general.autoRepair and E.db.general.autoRepair ~= "NONE" then
                    return "ElvUI"
                end
            end
            return nil
        end,
    },
    autoSellJunk = {
        name = "Auto-Venta de Basura Gris",
        nameEn = "Auto-Sell Grey Junk",
        icon = "Interface\\Icons\\INV_Misc_Coin_02",
        detectConflict = function()
            -- 1. EllesmereUI check
            if C_AddOns and (C_AddOns.IsAddOnLoaded("EllesmereUIQoL") or C_AddOns.IsAddOnLoaded("EllesmereUIBags") or C_AddOns.IsAddOnLoaded("EllesmereUI")) then
                return "EllesmereUI"
            end
            -- 2. ElvUI check
            if _G["ElvUI"] then
                local E = _G["ElvUI"][1]
                if E and E.db and E.db.general and E.db.general.vendorGrays == true then
                    return "ElvUI"
                end
            end
            return nil
        end,
    },
    fastLoot = {
        name = "Despojo Rápido Instantáneo (Fast Loot)",
        nameEn = "Fast Loot (0ms)",
        icon = "Interface\\Icons\\INV_Misc_Bag_10_Blue",
        detectConflict = function()
            -- 1. EllesmereUI check
            if C_AddOns and (C_AddOns.IsAddOnLoaded("EllesmereUIQoL") or C_AddOns.IsAddOnLoaded("EllesmereUI")) then
                return "EllesmereUI"
            end
            -- 2. ElvUI check
            if _G["ElvUI"] then
                return "ElvUI"
            end
            return nil
        end,
    },
    autoSkipCinematics = {
        name = "Auto-Saltar Cinemáticas Ya Vistas",
        nameEn = "Auto-Skip Watched Cinematics",
        icon = "Interface\\Icons\\INV_Misc_Eye_01",
        detectConflict = function()
            -- 1. EllesmereUI check
            if C_AddOns and (C_AddOns.IsAddOnLoaded("EllesmereUIQoL") or C_AddOns.IsAddOnLoaded("EllesmereUI")) then
                return "EllesmereUI"
            end
            -- 2. ElvUI check
            if _G["ElvUI"] then
                return "ElvUI"
            end
            return nil
        end,
    },
    bagSort = {
        name = "Ordenamiento de Bolsas & Materiales",
        nameEn = "Bag Sorting & Reagent Stash",
        icon = "Interface\\Icons\\INV_Misc_Bag_08",
        detectConflict = function()
            -- 1. EllesmereUI check
            if _G["EUI_Bags"] ~= nil or (C_AddOns and C_AddOns.IsAddOnLoaded("EllesmereUIBags")) then
                return "EllesmereUI"
            end
            -- 2. ElvUI check
            if _G["ElvUI"] then
                local E = _G["ElvUI"][1]
                if E and E.Bags and E.db and E.db.bags and E.db.bags.enable then
                    return "ElvUI"
                end
            end
            return nil
        end,
    },
}

DQ.ConflictResolver.DEFINITIONS = CONFLICT_DEFINITIONS

-- Checks if a specific feature currently conflicts with an external active addon
function DQ.ConflictResolver:DetectConflict(featureKey)
    local def = CONFLICT_DEFINITIONS[featureKey]
    if not def or not def.detectConflict then return nil end
    return def.detectConflict()
end

-- ==========================================================
-- SAVEDVARIABLES PERSISTENCE
-- ==========================================================
local function EnsureDB()
    if not DistractionQoLDB then
        DistractionQoLDB = {}
    end
    if not DistractionQoLDB.conflicts then
        DistractionQoLDB.conflicts = {
            choices = {},
            dontAskAgain = {},
        }
    end
    if not DistractionQoLDB.conflicts.choices then
        DistractionQoLDB.conflicts.choices = {}
    end
    if not DistractionQoLDB.conflicts.dontAskAgain then
        DistractionQoLDB.conflicts.dontAskAgain = {}
    end
    return DistractionQoLDB.conflicts
end

function DQ.ConflictResolver:GetChoice(featureKey)
    local db = EnsureDB()
    return db.choices[featureKey]
end

function DQ.ConflictResolver:GetDontAskAgain(featureKey)
    local db = EnsureDB()
    return db.dontAskAgain[featureKey] == true
end

-- Synchronizes feature state across DistractionQoL and external addons (EllesmereUI / ElvUI)
function DQ.ConflictResolver:ApplyHandover(featureKey, choice, extAddon)
    extAddon = extAddon or self:DetectConflict(featureKey)

    if featureKey == "fastLoot" then
        if choice == "DistractionQoL" then
            DQ.Config:Set("automation", "fastLoot", true)
            if extAddon == "EllesmereUI" and _G["EllesmereUIDB"] then
                _G["EllesmereUIDB"].quickLoot = false
                if _G["EllesmereUI"] and _G["EllesmereUI"]._applyQuickLoot then
                    pcall(_G["EllesmereUI"]._applyQuickLoot)
                end
            end
        elseif choice == "External" then
            DQ.Config:Set("automation", "fastLoot", false)
            if extAddon == "EllesmereUI" and _G["EllesmereUIDB"] then
                _G["EllesmereUIDB"].quickLoot = true
                if _G["EllesmereUI"] and _G["EllesmereUI"]._applyQuickLoot then
                    pcall(_G["EllesmereUI"]._applyQuickLoot)
                end
            end
        elseif choice == "Disabled" then
            DQ.Config:Set("automation", "fastLoot", false)
            if extAddon == "EllesmereUI" and _G["EllesmereUIDB"] then
                _G["EllesmereUIDB"].quickLoot = false
                if _G["EllesmereUI"] and _G["EllesmereUI"]._applyQuickLoot then
                    pcall(_G["EllesmereUI"]._applyQuickLoot)
                end
            end
        end

    elseif featureKey == "autoSkipCinematics" then
        if choice == "DistractionQoL" then
            DQ.Config:Set("automation", "autoSkipCinematics", true)
            if extAddon == "EllesmereUI" and _G["EllesmereUIDB"] then
                _G["EllesmereUIDB"].skipCinematicsAuto = false
            end
        elseif choice == "External" then
            DQ.Config:Set("automation", "autoSkipCinematics", false)
            if extAddon == "EllesmereUI" and _G["EllesmereUIDB"] then
                _G["EllesmereUIDB"].skipCinematics = true
                _G["EllesmereUIDB"].skipCinematicsAuto = true
            end
        elseif choice == "Disabled" then
            DQ.Config:Set("automation", "autoSkipCinematics", false)
            if extAddon == "EllesmereUI" and _G["EllesmereUIDB"] then
                _G["EllesmereUIDB"].skipCinematicsAuto = false
            end
        end

    elseif featureKey == "autoRepair" then
        if choice == "DistractionQoL" then
            DQ.Config:Set("automation", "autoRepair", true)
            if extAddon == "EllesmereUI" and _G["EllesmereUIDB"] then
                _G["EllesmereUIDB"].autoRepair = false
            end
        elseif choice == "External" then
            DQ.Config:Set("automation", "autoRepair", false)
            if extAddon == "EllesmereUI" and _G["EllesmereUIDB"] then
                _G["EllesmereUIDB"].autoRepair = true
            end
        elseif choice == "Disabled" then
            DQ.Config:Set("automation", "autoRepair", false)
            if extAddon == "EllesmereUI" and _G["EllesmereUIDB"] then
                _G["EllesmereUIDB"].autoRepair = false
            end
        end

    elseif featureKey == "autoSellJunk" then
        if choice == "DistractionQoL" then
            DQ.Config:Set("automation", "autoSellJunk", true)
            if extAddon == "EllesmereUI" and _G["EllesmereUIDB"] then
                _G["EllesmereUIDB"].autoSellJunk = false
            end
        elseif choice == "External" then
            DQ.Config:Set("automation", "autoSellJunk", false)
            if extAddon == "EllesmereUI" and _G["EllesmereUIDB"] then
                _G["EllesmereUIDB"].autoSellJunk = true
            end
        elseif choice == "Disabled" then
            DQ.Config:Set("automation", "autoSellJunk", false)
            if extAddon == "EllesmereUI" and _G["EllesmereUIDB"] then
                _G["EllesmereUIDB"].autoSellJunk = false
            end
        end

    elseif featureKey == "bagSort" then
        if choice == "DistractionQoL" then
            DQ.Config:Set("automation", "bagSortButton", true)
            DQ.Config:Set("automation", "overrideEllesmereSort", true)
        elseif choice == "External" then
            DQ.Config:Set("automation", "overrideEllesmereSort", false)
        elseif choice == "Disabled" then
            DQ.Config:Set("automation", "bagSortButton", false)
            DQ.Config:Set("automation", "overrideEllesmereSort", false)
        end
        if DQ.BagSort and DQ.BagSort.UpdateEllesmereIntegration then
            DQ.BagSort:UpdateEllesmereIntegration()
        end
        if DQ.BagSort and DQ.BagSort.UpdateBagButtonVisibility then
            DQ.BagSort:UpdateBagButtonVisibility()
        end
    end
end

function DQ.ConflictResolver:SetChoice(featureKey, choice, dontAskAgain)
    local db = EnsureDB()
    db.choices[featureKey] = choice
    if dontAskAgain ~= nil then
        db.dontAskAgain[featureKey] = dontAskAgain and true or false
    end
    self:ApplyHandover(featureKey, choice)
end

function DQ.ConflictResolver:ResetChoice(featureKey)
    local db = EnsureDB()
    db.choices[featureKey] = nil
    db.dontAskAgain[featureKey] = nil
    self:ApplyHandover(featureKey, "DistractionQoL")
end

function DQ.ConflictResolver:ResetAllChoices()
    local db = EnsureDB()
    db.choices = {}
    db.dontAskAgain = {}
    for key in pairs(CONFLICT_DEFINITIONS) do
        self:ApplyHandover(key, "DistractionQoL")
    end
    local L = DQ.L or {}
    PrintMsg(L["MSG_CONFLICTS_RESET"] or "Se han restablecido todas las elecciones de compatibilidad. Se te volverá a preguntar en caso de conflicto.")
end

-- ==========================================================
-- SLEEK OBSIDIAN MODAL POPUP DIALOG
-- ==========================================================
local dialogFrame = nil
local dialogQueue = {}
local isDialogShowing = false
local currentRequest = nil

local function CreateConflictDialog()
    if dialogFrame then return dialogFrame end

    local f = CreateFrame("Frame", "DistractionQoLConflictDialog", UIParent, "BackdropTemplate")
    f:SetSize(460, 230)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
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
    f:SetBackdropColor(0.08, 0.08, 0.12, 0.97)
    f:SetBackdropBorderColor(0.0, 0.85, 1.0, 0.9) -- Electric Cyan

    -- Header bar
    local headerBar = f:CreateTexture(nil, "BORDER")
    headerBar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    headerBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    headerBar:SetHeight(28)
    headerBar:SetColorTexture(0.04, 0.04, 0.06, 0.98)

    local headerAccent = f:CreateTexture(nil, "ARTWORK")
    headerAccent:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, 0)
    headerAccent:SetPoint("TOPRIGHT", headerBar, "BOTTOMRIGHT", 0, 0)
    headerAccent:SetHeight(1)
    headerAccent:SetColorTexture(0.0, 0.85, 1.0, 0.6)

    -- Header Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", headerBar, "LEFT", 10, 0)
    title:SetText("|cff00e5ffDistractionQoL|r - |cffffffffConflicto de Funcionalidad|r")
    f.title = title

    -- Close Button (X)
    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("RIGHT", headerBar, "RIGHT", -4, 0)
    closeBtn:SetNormalFontObject("GameFontNormalLarge")
    closeBtn:SetHighlightFontObject("GameFontHighlightLarge")
    closeBtn:SetText("X")
    closeBtn:SetScript("OnClick", function()
        f:Hide()
        if currentRequest and currentRequest.callback then
            currentRequest.callback("DistractionQoL", false)
        end
        DQ.ConflictResolver:ProcessNextDialog()
    end)

    -- Feature Icon Container
    local iconBg = f:CreateTexture(nil, "BORDER")
    iconBg:SetSize(40, 40)
    iconBg:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -44)
    iconBg:SetColorTexture(0.0, 0.85, 1.0, 0.3)

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetSize(36, 36)
    icon:SetPoint("CENTER", iconBg, "CENTER")
    icon:SetTexture("Interface\\Icons\\Trade_BlackSmithing")
    f.icon = icon

    -- Feature Title fontstring
    local featureTitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    featureTitle:SetPoint("TOPLEFT", iconBg, "TOPRIGHT", 12, 0)
    featureTitle:SetPoint("RIGHT", f, "RIGHT", -18, 0)
    featureTitle:SetJustifyH("LEFT")
    featureTitle:SetText("Auto-Reparación de Equipo")
    f.featureTitle = featureTitle

    -- Explanation description text
    local descText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    descText:SetPoint("TOPLEFT", featureTitle, "BOTTOMLEFT", 0, -6)
    descText:SetPoint("RIGHT", f, "RIGHT", -18, 0)
    descText:SetJustifyH("LEFT")
    descText:SetWordWrap(true)
    descText:SetText("Se ha detectado que EllesmereUI también tiene activa esta misma función.\n¿Qué addon deseas que gestione esta acción a partir de ahora?")
    f.descText = descText

    -- Checkbox: Don't ask again
    local cbDontAsk = CreateFrame("CheckButton", "DQConflictDontAskCB", f, "UICheckButtonTemplate")
    cbDontAsk:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 56)
    cbDontAsk:SetSize(20, 20)
    cbDontAsk:SetChecked(true)

    local cbText = cbDontAsk.text or _G[cbDontAsk:GetName() .. "Text"]
    if not cbText then
        cbText = cbDontAsk:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        cbText:SetPoint("LEFT", cbDontAsk, "RIGHT", 6, 0)
        cbDontAsk.text = cbText
    end
    cbText:SetText("Recordar mi elección (No volver a preguntar)")
    f.cbDontAsk = cbDontAsk

    -- Helper to create modern flat choice buttons
    local function CreateChoiceButton(parent, text, r, g, b)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(205, 30)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        btn:SetBackdropColor(0.12, 0.12, 0.16, 0.95)
        btn:SetBackdropBorderColor(r, g, b, 0.8)

        local t = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        t:SetPoint("CENTER")
        t:SetText(text)
        btn.text = t

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(r * 0.25, g * 0.25, b * 0.25, 1)
            self:SetBackdropBorderColor(r, g, b, 1)
            self.text:SetTextColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.12, 0.12, 0.16, 0.95)
            self:SetBackdropBorderColor(r, g, b, 0.8)
            self.text:SetTextColor(0.9, 0.9, 0.9, 1)
        end)

        return btn
    end

    -- Button 1: DistractionQoL
    local btnDQ = CreateChoiceButton(f, "Usar DistractionQoL", 0.0, 0.85, 1.0)
    btnDQ:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 16)
    btnDQ:SetScript("OnClick", function()
        local remember = cbDontAsk:GetChecked()
        f:Hide()
        if currentRequest and currentRequest.callback then
            currentRequest.callback("DistractionQoL", remember)
        end
        DQ.ConflictResolver:ProcessNextDialog()
    end)
    f.btnDQ = btnDQ

    -- Button 2: External Addon
    local btnExt = CreateChoiceButton(f, "Usar EllesmereUI", 0.65, 0.45, 0.95)
    btnExt:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 16)
    btnExt:SetScript("OnClick", function()
        local remember = cbDontAsk:GetChecked()
        f:Hide()
        if currentRequest and currentRequest.callback then
            currentRequest.callback("External", remember)
        end
        DQ.ConflictResolver:ProcessNextDialog()
    end)
    f.btnExt = btnExt

    dialogFrame = f
    return f
end

-- Displays the next dialog from the queue
function DQ.ConflictResolver:ProcessNextDialog()
    if #dialogQueue == 0 then
        isDialogShowing = false
        currentRequest = nil
        return
    end

    isDialogShowing = true
    currentRequest = table.remove(dialogQueue, 1)

    local f = CreateConflictDialog()
    local L = DQ.L or {}
    local isSpanish = (GetLocale() == "esES" or GetLocale() == "esMX")
    local def = CONFLICT_DEFINITIONS[currentRequest.featureKey] or {}

    -- Set feature icon
    f.icon:SetTexture(def.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

    -- Set feature title
    local featName = isSpanish and (def.name or currentRequest.featureKey) or (def.nameEn or currentRequest.featureKey)
    f.featureTitle:SetText("|cff00e5ff" .. featName .. "|r")

    -- Set explanation
    local extName = currentRequest.externalAddon or "EllesmereUI / ElvUI"
    if isSpanish then
        f.title:SetText("|cff00e5ffDistractionQoL|r - |cffffffffConflicto Detectado|r")
        f.descText:SetText(string.format("Se detectó que |cffffcc00%s|r también tiene habilitada la función de |cffffffff%s|r.\n¿Qué addon prefieres que realice esta acción?", extName, featName))
        f.btnDQ.text:SetText("Usar DistractionQoL")
        f.btnExt.text:SetText("Usar " .. extName)
        f.cbDontAsk.text:SetText("Recordar mi elección (No volver a preguntar)")
    else
        f.title:SetText("|cff00e5ffDistractionQoL|r - |cffffffffFeature Conflict Detected|r")
        f.descText:SetText(string.format("|cffffcc00%s|r also has |cffffffff%s|r enabled.\nWhich addon would you prefer to handle this action?", extName, featName))
        f.btnDQ.text:SetText("Use DistractionQoL")
        f.btnExt.text:SetText("Use " .. extName)
        f.cbDontAsk.text:SetText("Remember my choice (Don't ask again)")
    end

    f.cbDontAsk:SetChecked(true)
    f:Show()
end

-- Queues a conflict prompt request
function DQ.ConflictResolver:QueuePrompt(featureKey, externalAddon, callback)
    table.insert(dialogQueue, {
        featureKey = featureKey,
        externalAddon = externalAddon,
        callback = callback,
    })

    if not isDialogShowing then
        self:ProcessNextDialog()
    end
end

-- ==========================================================
-- MAIN DISPATCH GATEWAY
-- ==========================================================
-- Checks if a feature has an active external conflict.
-- If no conflict: runs onDistractionQoL() immediately.
-- If user already chose with dontAskAgain: honors the choice immediately.
-- If conflict requires user decision: shows dialog, saves choice, and runs selected branch.
function DQ.ConflictResolver:CheckAndExecute(featureKey, onDistractionQoL, onExternal)
    local choice = self:GetChoice(featureKey)
    if choice == "Disabled" then
        -- Feature is explicitly disabled by user in Compatibility
        return
    end

    local externalAddon = self:DetectConflict(featureKey)
    if not externalAddon then
        -- No conflicting addon active for this feature
        if onDistractionQoL then onDistractionQoL() end
        return
    end

    local dontAsk = self:GetDontAskAgain(featureKey)

    if (dontAsk and choice) or choice == "External" or choice == "DistractionQoL" then
        if choice == "DistractionQoL" then
            if onDistractionQoL then onDistractionQoL() end
        else
            if onExternal then onExternal() end
        end
        return
    end

    -- Queue modal dialog prompt
    self:QueuePrompt(featureKey, externalAddon, function(selectedChoice, remember)
        self:SetChoice(featureKey, selectedChoice, remember)
        if selectedChoice == "DistractionQoL" then
            if onDistractionQoL then onDistractionQoL() end
        else
            if onExternal then onExternal() end
        end
    end)
end
