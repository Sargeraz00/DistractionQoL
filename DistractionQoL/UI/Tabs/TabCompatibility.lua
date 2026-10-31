-- TabCompatibility.lua
-- Page 5: Conflicts & Compatibility settings
-- Manages coexistence with EllesmereUI and ElvUI, per-feature delegation toggles, and live feedback alerts

local addonName, DQ = ...

DQ.UI = DQ.UI or {}

function DQ.UI:BuildTabCompatibility(parentFrame, pConflicts)
    local L = DQ.L or {}
    local m3 = (DQ.Theme and DQ.Theme.M3) or {}

    local confTitle = pConflicts:CreateFontString(nil, "OVERLAY")
    confTitle:SetPoint("TOPLEFT", pConflicts, "TOPLEFT", 6, 0)
    DQ.Theme.ApplyText(confTitle, 14, "bold", m3.primary)
    confTitle:SetText(L["SECTION_CONFLICTS_TITLE"] or "Resolución de Conflictos & Compatibilidad")

    local confDesc = pConflicts:CreateFontString(nil, "OVERLAY")
    confDesc:SetPoint("TOPLEFT", confTitle, "BOTTOMLEFT", 0, -3)
    confDesc:SetPoint("RIGHT", pConflicts, "RIGHT", -4, 0)
    confDesc:SetJustifyH("LEFT")
    confDesc:SetWordWrap(true)
    DQ.Theme.ApplyText(confDesc, 11, "regular", m3.onSurfaceVariant)
    confDesc:SetText(L["SECTION_CONFLICTS_DESC"] or "Detecta funciones compartidas con EllesmereUI y ElvUI. Puedes definir qué addon controla cada función o restablecer los avisos emergentes.")

    -- Feedback alert banner displayed on selection changes
    local confFeedback = pConflicts:CreateFontString(nil, "OVERLAY")
    confFeedback:SetPoint("TOPLEFT", confDesc, "BOTTOMLEFT", 0, -3)
    confFeedback:SetPoint("RIGHT", pConflicts, "RIGHT", -4, 0)
    confFeedback:SetJustifyH("LEFT")
    confFeedback:SetWordWrap(false)
    DQ.Theme.ApplyText(confFeedback, 11, "semibold", m3.secondary)
    confFeedback:SetText("")

    local feedbackSeq = 0
    local function ShowFeedback(featureKey, choice, extName)
        local def = (DQ.ConflictResolver and DQ.ConflictResolver.DEFINITIONS and DQ.ConflictResolver.DEFINITIONS[featureKey]) or {}
        local isSpanish = (GetLocale() == "esES" or GetLocale() == "esMX")
        local featName = isSpanish and (def.name or featureKey) or (def.nameEn or featureKey)
        local target = (choice == "DistractionQoL") and "DistractionQoL" or (extName or "Externo")

        local msg
        if choice == "Disabled" then
            msg = isSpanish
                and string.format("|cffff4444[Desactivado]|r '%s' ha sido desactivada.", featName)
                or string.format("|cffff4444[Disabled]|r '%s' has been disabled.", featName)
        else
            msg = isSpanish
                and string.format("|cff00ff00[Guardado]|r '%s' ahora es gestionado por |cff00e5ff%s|r.", featName, target)
                or string.format("|cff00ff00[Saved]|r '%s' is now managed by |cff00e5ff%s|r.", featName, target)
        end

        confFeedback:SetText(msg)

        local prefix = "|cff00e5ff[DistractionQoL]|r "
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage(prefix .. msg)
        end

        feedbackSeq = feedbackSeq + 1
        local currentSeq = feedbackSeq
        C_Timer.After(4, function()
            if confFeedback and feedbackSeq == currentSeq then
                confFeedback:SetText("")
            end
        end)
    end

    local conflictRows = {}
    local featureOrder = { "autoRepair", "autoSellJunk", "fastLoot", "autoSkipCinematics", "bagSort", "consumables" }

    local function RefreshConflictRows()
        if not DQ.ConflictResolver then return end
        local defs = DQ.ConflictResolver.DEFINITIONS or {}
        local isSpanish = (GetLocale() == "esES" or GetLocale() == "esMX")

        for _, key in ipairs(featureOrder) do
            local def = defs[key]
            local row = conflictRows[key]
            if def and row then
                local ext = DQ.ConflictResolver:DetectConflict(key)
                local currentChoice = DQ.ConflictResolver:GetChoice(key)
                if currentChoice == nil then
                    currentChoice = "DistractionQoL"
                end

                if ext then
                    row.btnExt:SetButtonText(ext)
                    row.btnExt:Show()

                    if currentChoice == "DistractionQoL" then
                        row.btnDQ:SetSelected(true, "DistractionQoL")
                        row.btnExt:SetSelected(false, ext)
                        row.statusText:SetText(isSpanish
                            and string.format("|cff00ff99Gestionado por:|r DistractionQoL |cff666677(%s detectado)|r", ext)
                            or string.format("|cff00ff99Managed by:|r DistractionQoL |cff666677(%s detected)|r", ext))

                    elseif currentChoice == "External" then
                        row.btnDQ:SetSelected(false, "DistractionQoL")
                        row.btnExt:SetSelected(true, ext)
                        row.statusText:SetText(isSpanish
                            and string.format("|cffcc88ffGestionado por:|r %s |cff666677(cedido por DQ)|r", ext)
                            or string.format("|cffcc88ffManaged by:|r %s |cff666677(ceded by DQ)|r", ext))

                    else -- "Disabled"
                        row.btnDQ:SetSelected(false, "DistractionQoL")
                        row.btnExt:SetSelected(false, ext)
                        row.statusText:SetText(isSpanish
                            and string.format("|cffff4444[Desactivado]|r Ningún addon ejecutará esta acción |cff666677(%s detectado)|r", ext)
                            or string.format("|cffff4444[Disabled]|r No addon will perform this action |cff666677(%s detected)|r", ext))
                    end
                else
                    row.btnExt:Hide()

                    if currentChoice == "DistractionQoL" then
                        row.btnDQ:SetSelected(true, "DistractionQoL")
                        row.statusText:SetText(isSpanish
                            and "|cff00ff99Activo:|r DistractionQoL |cff666677(sin conflicto)|r"
                            or "|cff00ff99Active:|r DistractionQoL |cff666677(no conflict)|r")
                    else
                        row.btnDQ:SetSelected(false, "DistractionQoL")
                        row.statusText:SetText(isSpanish
                            and "|cffff4444[Desactivado]|r Función apagada |cff666677(sin conflicto)|r"
                            or "|cffff4444[Disabled]|r Feature disabled |cff666677(no conflict)|r")
                    end
                end
            end
        end
    end

    local rowStartY = -60
    local rowHeight = 48

    for i, key in ipairs(featureOrder) do
        local def = (DQ.ConflictResolver and DQ.ConflictResolver.DEFINITIONS and DQ.ConflictResolver.DEFINITIONS[key]) or {}
        local isSpanish = (GetLocale() == "esES" or GetLocale() == "esMX")
        local name = isSpanish and (def.name or key) or (def.nameEn or key)

        local rowY = rowStartY - (i - 1) * rowHeight

        local rowBg = pConflicts:CreateTexture(nil, "BACKGROUND")
        rowBg:SetPoint("TOPLEFT", pConflicts, "TOPLEFT", 0, rowY)
        rowBg:SetPoint("BOTTOMRIGHT", pConflicts, "TOPRIGHT", 0, rowY - 42)
        rowBg:SetColorTexture(unpack(m3.surfaceContainerHigh or { 0.22, 0.28, 0.31, 0.45 }))

        local icon = pConflicts:CreateTexture(nil, "ARTWORK")
        icon:SetSize(28, 28)
        icon:SetPoint("LEFT", pConflicts, "TOPLEFT", 8, rowY - 21)
        icon:SetTexture(def.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

        local btnExt = self:CreateChoiceButton(pConflicts, 112, 24, "External")
        btnExt:SetPoint("RIGHT", pConflicts, "TOPRIGHT", -8, rowY - 21)

        local btnDQ = self:CreateChoiceButton(pConflicts, 112, 24, "DistractionQoL")
        btnDQ:SetPoint("RIGHT", pConflicts, "TOPRIGHT", -124, rowY - 21)

        local lblName = pConflicts:CreateFontString(nil, "OVERLAY")
        lblName:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 3)
        lblName:SetPoint("RIGHT", btnDQ, "LEFT", -8, 0)
        lblName:SetJustifyH("LEFT")
        lblName:SetWordWrap(false)
        DQ.Theme.ApplyText(lblName, 12, "semibold", m3.onSurface)
        lblName:SetText(name)

        local lblStatus = pConflicts:CreateFontString(nil, "OVERLAY")
        lblStatus:SetPoint("TOPLEFT", lblName, "BOTTOMLEFT", 0, -3)
        lblStatus:SetPoint("RIGHT", btnDQ, "LEFT", -8, 0)
        lblStatus:SetJustifyH("LEFT")
        lblStatus:SetWordWrap(false)
        DQ.Theme.ApplyText(lblStatus, 11, "regular", m3.onSurfaceVariant)
        lblStatus:SetText("Verificando...")

        btnDQ:SetScript("OnClick", function()
            if DQ.ConflictResolver then
                local currentChoice = DQ.ConflictResolver:GetChoice(key)
                if currentChoice == nil then currentChoice = "DistractionQoL" end

                local newChoice
                if currentChoice == "DistractionQoL" then
                    newChoice = "Disabled"
                    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
                else
                    newChoice = "DistractionQoL"
                    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                end

                DQ.ConflictResolver:SetChoice(key, newChoice, true)
                RefreshConflictRows()
                ShowFeedback(key, newChoice, nil)
            end
        end)

        btnExt:SetScript("OnClick", function()
            if DQ.ConflictResolver then
                local ext = DQ.ConflictResolver:DetectConflict(key) or "Externo"
                local currentChoice = DQ.ConflictResolver:GetChoice(key)
                if currentChoice == nil then currentChoice = "DistractionQoL" end

                local newChoice
                if currentChoice == "External" then
                    newChoice = "Disabled"
                    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
                else
                    newChoice = "External"
                    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                end

                DQ.ConflictResolver:SetChoice(key, newChoice, true)
                RefreshConflictRows()
                ShowFeedback(key, newChoice, ext)
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

    local btnResetConflicts = self:CreateM3Button(pConflicts, L["BTN_RESET_CONFLICTS"] or "Restablecer Avisos (Volver a Preguntar)", "tonal", 290, 26)
    btnResetConflicts:SetPoint("BOTTOMLEFT", pConflicts, "BOTTOMLEFT", 4, 8)
    btnResetConflicts:SetScript("OnClick", function()
        if DQ.ConflictResolver then
            DQ.ConflictResolver:ResetAllChoices()
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
            RefreshConflictRows()
            local isSpanish = (GetLocale() == "esES" or GetLocale() == "esMX")
            local msg = isSpanish
                and "|cff00ff00[Restablecido]|r Avisos de conflicto restablecidos. Se volverá a preguntar ante nuevos conflictos."
                or "|cff00ff00[Reset]|r Conflict prompts reset. Will prompt again on next conflict."
            confFeedback:SetText(msg)
            feedbackSeq = feedbackSeq + 1
            local currentSeq = feedbackSeq
            C_Timer.After(4, function()
                if confFeedback and feedbackSeq == currentSeq then
                    confFeedback:SetText("")
                end
            end)
        end
    end)

    pConflicts:SetScript("OnShow", function()
        RefreshConflictRows()
    end)

    parentFrame.RefreshConflictRows = RefreshConflictRows
end
