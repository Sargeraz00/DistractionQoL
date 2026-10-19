-- UtilityRadar.lua
-- LFG Composition & Utility Radar for DistractionQoL
-- Analyzes Premade Group Finder (LFG) listings in real time to detect missing utilities:
-- Bloodlust/Heroism, Battle Resurrection (BRez), and class saturation.
-- Highlights high-probability groups where the player's class provides the missing key utility.
-- Zero taint, secure execution using hooksecurefunc.

local addonName, DQ = ...

DQ.UtilityRadar = {}

-- Utility class maps
local LUST_CLASSES = {
    ["MAGE"]   = true,
    ["SHAMAN"] = true,
    ["EVOKER"] = true,
    ["HUNTER"] = true,
}

local BREZ_CLASSES = {
    ["WARLOCK"]     = true,
    ["DRUID"]       = true,
    ["DEATHKNIGHT"] = true,
    ["PALADIN"]     = true,
}

-- Helper to safely check secret values in Midnight 12.x
local function IsSecret(val)
    return issecretvalue and issecretvalue(val)
end

-- Analyzes utility state for a given LFG resultID
local function AnalyzeGroupUtility(resultID)
    if not resultID or not C_LFGList or not C_LFGList.GetSearchResultInfo then
        return nil
    end

    local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
    if not searchResultInfo or IsSecret(searchResultInfo) or searchResultInfo.isDelisted then
        return nil
    end

    local numMembers = searchResultInfo.numMembers or 0
    if numMembers == 0 then
        return nil
    end

    local _, playerClass = UnitClass("player")
    local members = {}

    for i = 1, numMembers do
        local classToken, classLocalized
        if C_LFGList.GetSearchResultPlayerInfo then
            local pInfo = C_LFGList.GetSearchResultPlayerInfo(resultID, i)
            if pInfo and not IsSecret(pInfo) then
                classToken = pInfo.classFilename
                classLocalized = pInfo.className
            end
        elseif C_LFGList.GetSearchResultMemberInfo then
            local _, cToken, cLoc = C_LFGList.GetSearchResultMemberInfo(resultID, i)
            classToken = cToken
            classLocalized = cLoc
        end

        if classToken and not IsSecret(classToken) then
            table.insert(members, {
                classToken = classToken,
                classLocalized = classLocalized,
            })
        end
    end

    local highlightEnabled = DQ.Config:Get("lfgRadar", "highlightRecommended") ~= false
    if DQ.UtilityRadarLogic and DQ.UtilityRadarLogic.EvaluateGroup then
        return DQ.UtilityRadarLogic.EvaluateGroup(members, playerClass, highlightEnabled)
    end
    return nil
end

-- Hook: Appends utility analysis to LFG search entry tooltip
local function OnSetSearchEntryTooltip(tooltip, resultID)
    if not tooltip or not resultID then return end

    local cfg = DQ.Config and DQ.Config:Get("lfgRadar")
    if not cfg or cfg.enabled == false or cfg.showTooltipAnalysis == false then
        return
    end

    local analysis = AnalyzeGroupUtility(resultID)
    if not analysis then return end

    local L = DQ.L or {}

    tooltip:AddLine(" ")
    tooltip:AddLine("|cff00e5ff" .. (L["LFG_RADAR_HEADER"] or "DistractionQoL — Radar de Grupo:") .. "|r")

    -- Bloodlust line
    local lustStatus
    if analysis.hasLust then
        lustStatus = string.format("%s |cff888888(%s)|r", L["LFG_RADAR_AVAILABLE"] or "|cff00ff88[DISPONIBLE]|r", analysis.lustProviderName or "")
    else
        lustStatus = L["LFG_RADAR_MISSING"] or "|cffff4444[FALTA]|r"
        if analysis.playerProvidesLust then
            lustStatus = lustStatus .. " " .. (L["LFG_RADAR_YOU_PROVIDE"] or "|cffffd100★ ¡Tú lo aportas!|r")
        end
    end
    tooltip:AddDoubleLine("  " .. (L["LFG_RADAR_LUST"] or "Heroísmo / Bloodlust:"), lustStatus)

    -- Battle Rez line
    local brezStatus
    if analysis.hasBrez then
        brezStatus = string.format("%s |cff888888(%s)|r", L["LFG_RADAR_AVAILABLE"] or "|cff00ff88[DISPONIBLE]|r", analysis.brezProviderName or "")
    else
        brezStatus = L["LFG_RADAR_MISSING"] or "|cffff4444[FALTA]|r"
        if analysis.playerProvidesBrez then
            brezStatus = brezStatus .. " " .. (L["LFG_RADAR_YOU_PROVIDE"] or "|cffffd100★ ¡Tú lo aportas!|r")
        end
    end
    tooltip:AddDoubleLine("  " .. (L["LFG_RADAR_BREZ"] or "Resurrección en Combate:"), brezStatus)

    -- Duplicate class warning
    if analysis.myClassCount >= 2 then
        local warnStr = string.format(L["LFG_RADAR_SATURATED"] or "|cffff8844(Aviso: ya hay %d de tu clase en este grupo)|r", analysis.myClassCount)
        tooltip:AddLine("  " .. warnStr)
    end

    -- Verdict
    if analysis.isRecommended then
        tooltip:AddLine("  " .. (L["LFG_RADAR_VERDICT_HIGH"] or "|cff00ff88★ ¡Alta probabilidad de invitación para tu clase!|r"))
    end

    tooltip:Show()
end

-- Hook: Adds micro badges [BL] [CR] and recommendation highlights directly on list rows
local function OnSearchEntryUpdate(entry)
    if not entry or not entry.resultID then return end

    local cfg = DQ.Config and DQ.Config:Get("lfgRadar")
    if not cfg or cfg.enabled == false or cfg.showEntryBadges == false then
        if entry._dqRadarText then
            entry._dqRadarText:SetText("")
        end
        return
    end

    local analysis = AnalyzeGroupUtility(entry.resultID)
    if not analysis then
        if entry._dqRadarText then
            entry._dqRadarText:SetText("")
        end
        return
    end

    -- Create or reuse overlay FontString on entry
    if not entry._dqRadarText then
        local fs = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("RIGHT", entry, "RIGHT", -12, 0)
        entry._dqRadarText = fs
    end

    local blBadge = analysis.hasLust and "|cff00ff88BL|r" or "|cffff4444BL|r"
    local crBadge = analysis.hasBrez and "|cff00ff88CR|r" or "|cffff4444CR|r"

    local badgeStr = string.format("[%s|r %s|r]", blBadge, crBadge)

    if analysis.isRecommended then
        badgeStr = "|cffffd100★|r " .. badgeStr
    end

    entry._dqRadarText:SetText(badgeStr)
end

function DQ.UtilityRadar:Init()
    local function SetupHooks()
        if self._hooked then return end
        self._hooked = true

        if LFGListUtil_SetSearchEntryTooltip then
            hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", OnSetSearchEntryTooltip)
        end
        if LFGListSearchEntry_Update then
            hooksecurefunc("LFGListSearchEntry_Update", OnSearchEntryUpdate)
        end
    end

    -- Check if Blizzard_GroupFinder is already loaded
    if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_GroupFinder") then
        SetupHooks()
    else
        local f = CreateFrame("Frame")
        f:RegisterEvent("ADDON_LOADED")
        f:SetScript("OnEvent", function(self, event, loadedAddon)
            if loadedAddon == "Blizzard_GroupFinder" then
                SetupHooks()
                self:UnregisterEvent("ADDON_LOADED")
            end
        end)
    end
end
