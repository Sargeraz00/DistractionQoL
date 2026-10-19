-- TabTooltips.lua
-- Page 4: Tooltip context, item count breakdown, reagent expansion, and loot trade advisor settings
-- Uses a balanced two-column layout for maximum legibility and zero clipping

local addonName, DQ = ...

DQ.UI = DQ.UI or {}

function DQ.UI:BuildTabTooltips(parentFrame, pTooltips)
    local L = DQ.L or {}

    -- ==========================================================
    -- LEFT COLUMN: INVENTORY ITEM COUNTS (X = 8)
    -- ==========================================================
    local secCounts = pTooltips:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    secCounts:SetPoint("TOPLEFT", pTooltips, "TOPLEFT", 8, 0)
    secCounts:SetText("|cff00e5ff" .. (L["TOOLTIP_ITEM_COUNT_TITLE"] or "Desglose de Inventario en Objetos") .. "|r")

    local cbBags, cbBank, cbWarband, cbTotal, cbHideSingle, cbShift

    local function UpdateSubCountStates(enabled)
        local alpha = enabled and 1 or 0.45
        for _, cb in ipairs({cbBags, cbBank, cbWarband, cbTotal, cbHideSingle, cbShift}) do
            if cb then
                cb:SetEnabled(enabled)
                if cb.text then cb.text:SetTextColor(alpha, alpha, alpha) end
            end
        end
    end

    local isCountsEnabled = DQ.Config:Get("tooltip", "itemCount", "enabled") ~= false

    self:CreateCheckbox(pTooltips, L["TOOLTIP_ITEM_COUNT_ENABLE"] or "Activar Desglose en Tooltips", 8, -24, isCountsEnabled, function(checked)
        DQ.Config:Set("tooltip", "itemCount", "enabled", checked)
        UpdateSubCountStates(checked)
    end)

    cbBags = self:CreateCheckbox(pTooltips, L["TOOLTIP_ITEM_COUNT_BAGS"] or "Mostrar en Bolsas", 24, -48, DQ.Config:Get("tooltip", "itemCount", "showBags"), function(checked)
        DQ.Config:Set("tooltip", "itemCount", "showBags", checked)
    end)

    cbBank = self:CreateCheckbox(pTooltips, L["TOOLTIP_ITEM_COUNT_BANK"] or "Mostrar en Banco Personal", 24, -72, DQ.Config:Get("tooltip", "itemCount", "showBank"), function(checked)
        DQ.Config:Set("tooltip", "itemCount", "showBank", checked)
    end)

    cbWarband = self:CreateCheckbox(pTooltips, L["TOOLTIP_ITEM_COUNT_WARBAND"] or "Mostrar en Banda Guerrera", 24, -96, DQ.Config:Get("tooltip", "itemCount", "showWarband"), function(checked)
        DQ.Config:Set("tooltip", "itemCount", "showWarband", checked)
    end)

    cbTotal = self:CreateCheckbox(pTooltips, L["TOOLTIP_ITEM_COUNT_TOTAL"] or "Mostrar Suma Total", 24, -120, DQ.Config:Get("tooltip", "itemCount", "showTotal"), function(checked)
        DQ.Config:Set("tooltip", "itemCount", "showTotal", checked)
    end)

    cbHideSingle = self:CreateCheckbox(pTooltips, L["TOOLTIP_ITEM_COUNT_HIDE_SINGLE"] or "Ocultar si solo tienes 1 en bolsas", 24, -144, DQ.Config:Get("tooltip", "itemCount", "hideSingle"), function(checked)
        DQ.Config:Set("tooltip", "itemCount", "hideSingle", checked)
    end)

    cbShift = self:CreateCheckbox(pTooltips, L["TOOLTIP_ITEM_COUNT_SHIFT"] or "Mostrar solo con SHIFT", 24, -168, DQ.Config:Get("tooltip", "itemCount", "requireShift"), function(checked)
        DQ.Config:Set("tooltip", "itemCount", "requireShift", checked)
    end)

    UpdateSubCountStates(isCountsEnabled)

    -- ==========================================================
    -- RIGHT COLUMN: REAGENTS, MOBS & LOOT ADVISOR (X = 276)
    -- ==========================================================
    local colX = 276

    -- 1. Crafting Reagents
    local secReagents = pTooltips:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    secReagents:SetPoint("TOPLEFT", pTooltips, "TOPLEFT", colX, 0)
    secReagents:SetText("|cff00e5ff" .. (L["TOOLTIP_REAGENTS_TITLE"] or "Materiales de Profesión") .. "|r")

    local cbCurrentExpac
    local isReagentsEnabled = DQ.Config:Get("tooltip", "reagentExpansion", "enabled") ~= false

    self:CreateCheckbox(pTooltips, L["TOOLTIP_REAGENTS_ENABLE"] or "Mostrar Expansión en Materiales", colX, -24, isReagentsEnabled, function(checked)
        DQ.Config:Set("tooltip", "reagentExpansion", "enabled", checked)
        if cbCurrentExpac then
            cbCurrentExpac:SetEnabled(checked)
            if cbCurrentExpac.text then cbCurrentExpac.text:SetTextColor(checked and 1 or 0.45, checked and 1 or 0.45, checked and 1 or 0.45) end
        end
    end)

    cbCurrentExpac = self:CreateCheckbox(pTooltips, L["TOOLTIP_REAGENTS_CURRENT"] or "Resaltar actual (Midnight)", colX + 16, -48, DQ.Config:Get("tooltip", "reagentExpansion", "colorCurrent"), function(checked)
        DQ.Config:Set("tooltip", "reagentExpansion", "colorCurrent", checked)
    end)

    if cbCurrentExpac then
        cbCurrentExpac:SetEnabled(isReagentsEnabled)
        if cbCurrentExpac.text then cbCurrentExpac.text:SetTextColor(isReagentsEnabled and 1 or 0.45, isReagentsEnabled and 1 or 0.45, isReagentsEnabled and 1 or 0.45) end
    end

    -- 2. Mobs / Targeted By
    local secMobs = pTooltips:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    secMobs:SetPoint("TOPLEFT", pTooltips, "TOPLEFT", colX, -82)
    secMobs:SetText("|cff00e5ff" .. (L["TOOLTIP_MOBS_TITLE"] or "Combate & PNJs") .. "|r")

    self:CreateCheckbox(pTooltips, L["OPT_TOOLTIP_TARGETED_BY"] or "Mostrar enfocadores (Targeted By)", colX, -104, DQ.Config:Get("tooltip", "targetedBy"), function(checked)
        DQ.Config:Set("tooltip", "targetedBy", checked)
    end)

    -- 3. Loot Trade Advisor
    local secLoot = pTooltips:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    secLoot:SetPoint("TOPLEFT", pTooltips, "TOPLEFT", colX, -138)
    secLoot:SetText("|cff00e5ff" .. (L["LOOT_ADVISOR_TITLE"] or "Asesor de Botín Comerciable") .. "|r")

    local cbOnlyEligible, cbOnlyUpgrades

    local function UpdateLootSubStates(enabled)
        local alpha = enabled and 1 or 0.45
        for _, cb in ipairs({cbOnlyEligible, cbOnlyUpgrades}) do
            if cb then
                cb:SetEnabled(enabled)
                if cb.text then cb.text:SetTextColor(alpha, alpha, alpha) end
            end
        end
    end

    local isLootAdvisorEnabled = DQ.Config:Get("loot", "tradeAdvisor") ~= false

    self:CreateCheckbox(pTooltips, L["LOOT_OPT_ADVISOR"] or "Ventana de botín comerciable al terminar", colX, -160, isLootAdvisorEnabled, function(checked)
        DQ.Config:Set("loot", "tradeAdvisor", checked)
        UpdateLootSubStates(checked)
    end)

    cbOnlyEligible = self:CreateCheckbox(pTooltips, L["LOOT_OPT_ONLY_ELIGIBLE"] or "Solo equipo utilizable por tu clase", colX + 16, -184, DQ.Config:Get("loot", "onlyEligible"), function(checked)
        DQ.Config:Set("loot", "onlyEligible", checked)
    end)

    cbOnlyUpgrades = self:CreateCheckbox(pTooltips, L["LOOT_OPT_ONLY_UPGRADES"] or "Solo piezas que mejoren tu ilvl", colX + 16, -208, DQ.Config:Get("loot", "onlyUpgrades"), function(checked)
        DQ.Config:Set("loot", "onlyUpgrades", checked)
    end)

    UpdateLootSubStates(isLootAdvisorEnabled)

    -- Test Loot Advisor Button
    local btnTestLoot = self:CreateFlatButton(pTooltips, L["BTN_TEST_LOOT"] or "Probar Asesor de Botín", 180, 22)
    btnTestLoot:SetPoint("TOPLEFT", pTooltips, "TOPLEFT", colX + 16, -238)
    btnTestLoot:SetScript("OnClick", function()
        if DQ.TradeAdvisor and DQ.TradeAdvisor.SimulateTestLoot then
            DQ.TradeAdvisor:SimulateTestLoot()
        end
    end)
end
