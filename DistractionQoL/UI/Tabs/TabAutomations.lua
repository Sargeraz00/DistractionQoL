-- TabAutomations.lua
-- Page 3: Automations QoL settings
-- Manages auto-repair, auto-sell junk, fast loot, movie skipping, keystone auto-slot, and bag sorting

local addonName, DQ = ...

DQ.UI = DQ.UI or {}

function DQ.UI:BuildTabAutomations(parentFrame, pAuto)
    local L = DQ.L or {}

    local autoTitle = pAuto:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoTitle:SetPoint("TOPLEFT", pAuto, "TOPLEFT", 4, 0)
    autoTitle:SetText("|cff00e5ff" .. (L["SECTION_AUTO_TITLE"] or "Automatizaciones QoL") .. "|r")

    local autoDesc = pAuto:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    autoDesc:SetPoint("TOPLEFT", autoTitle, "BOTTOMLEFT", 0, -4)
    autoDesc:SetText(L["SECTION_AUTO_DESC"] or "Acciones instantáneas sin spam de eventos ni sobrecoste de CPU.")

    -- 1. Auto Res
    local cbAutoResCombat
    self:CreateCheckbox(pAuto, L["AUTO_RES"] or "Auto-aceptar Resurrección en wipes", 8, -46, DQ.Config:Get("automation", "autoRes", "enabled"), function(checked)
        DQ.Config:Set("automation", "autoRes", "enabled", checked)
        if cbAutoResCombat then
            cbAutoResCombat:SetEnabled(checked)
            cbAutoResCombat.text:SetTextColor(checked and 1 or 0.45, checked and 1 or 0.45, checked and 1 or 0.45)
        end
    end)

    cbAutoResCombat = self:CreateCheckbox(pAuto, L["AUTO_RES_COMBAT"] or "Permitir auto-aceptar en combate (Battle Rez)", 32, -72, DQ.Config:Get("automation", "autoRes", "inCombat"), function(checked)
        DQ.Config:Set("automation", "autoRes", "inCombat", checked)
    end)
    local autoResActive = DQ.Config:Get("automation", "autoRes", "enabled")
    cbAutoResCombat:SetEnabled(autoResActive)
    cbAutoResCombat.text:SetTextColor(autoResActive and 1 or 0.45, autoResActive and 1 or 0.45, autoResActive and 1 or 0.45)

    -- 2. Auto Repair & Guild Repair
    local cbGuildRepair
    self:CreateCheckbox(pAuto, L["AUTO_REPAIR"] or "Auto-reparar equipo en mercader", 8, -102, DQ.Config:Get("automation", "autoRepair"), function(checked)
        DQ.Config:Set("automation", "autoRepair", checked)
        if cbGuildRepair then
            cbGuildRepair:SetEnabled(checked)
            cbGuildRepair.text:SetTextColor(checked and 1 or 0.45, checked and 1 or 0.45, checked and 1 or 0.45)
        end
    end)

    cbGuildRepair = self:CreateCheckbox(pAuto, L["GUILD_REPAIR"] or "Priorizar fondos de hermandad para reparaciones", 32, -128, DQ.Config:Get("automation", "guildRepair"), function(checked)
        DQ.Config:Set("automation", "guildRepair", checked)
    end)
    local repairActive = DQ.Config:Get("automation", "autoRepair")
    cbGuildRepair:SetEnabled(repairActive)
    cbGuildRepair.text:SetTextColor(repairActive and 1 or 0.45, repairActive and 1 or 0.45, repairActive and 1 or 0.45)

    -- 3. Auto Sell Junk
    self:CreateCheckbox(pAuto, L["AUTO_SELL_JUNK"] or "Auto-vender basura gris en mercader", 8, -158, DQ.Config:Get("automation", "autoSellJunk"), function(checked)
        DQ.Config:Set("automation", "autoSellJunk", checked)
    end)

    -- 4. Auto Skip Movies
    self:CreateCheckbox(pAuto, L["AUTO_SKIP_MOVIES"] or "Auto-saltar cinemáticas ya vistas en bosses", 8, -186, DQ.Config:Get("automation", "autoSkipCinematics"), function(checked)
        DQ.Config:Set("automation", "autoSkipCinematics", checked)
    end)

    -- 5. Block Duels
    self:CreateCheckbox(pAuto, L["BLOCK_DUELS"] or "Bloquear invitaciones a duelos dentro de mazmorras/raid", 8, -214, DQ.Config:Get("automation", "blockDuels"), function(checked)
        DQ.Config:Set("automation", "blockDuels", checked)
    end)

    -- 6. Fast Loot
    self:CreateCheckbox(pAuto, L["FAST_LOOT"] or "Despojo rápido instantáneo (Fast Loot a 0ms)", 8, -242, DQ.Config:Get("automation", "fastLoot"), function(checked)
        DQ.Config:Set("automation", "fastLoot", checked)
    end)

    -- 7. Reverse Bag Sort & Reagents Stash
    self:CreateCheckbox(pAuto, L["BAG_SORT_BUTTON"] or "Mostrar botón de Orden Inverso en las bolsas", 8, -270, DQ.Config:Get("automation", "bagSortButton"), function(checked)
        DQ.Config:Set("automation", "bagSortButton", checked)
        if DQ.BagSort and DQ.BagSort.UpdateBagButtonVisibility then
            DQ.BagSort:UpdateBagButtonVisibility()
        end
    end)

    -- 8. EllesmereUI Sort Override
    self:CreateCheckbox(pAuto, L["OVERRIDE_ELLESMERE_SORT"] or "EllesmereUI: Reemplazar su botón de ordenar con DistractionQoL", 8, -298, DQ.Config:Get("automation", "overrideEllesmereSort"), function(checked)
        DQ.Config:Set("automation", "overrideEllesmereSort", checked)
        if DQ.BagSort and DQ.BagSort.UpdateEllesmereIntegration then
            DQ.BagSort:UpdateEllesmereIntegration()
        end
    end)

    local btnSortNow = self:CreateFlatButton(pAuto, L["BTN_SORT_BAGS"] or "Ordenar Bolsas Ahora", 180, 22)
    btnSortNow:SetPoint("TOPLEFT", pAuto, "TOPLEFT", 8, -330)
    btnSortNow:SetScript("OnClick", function()
        if DQ.BagSort then DQ.BagSort:SortBags() end
    end)
end
