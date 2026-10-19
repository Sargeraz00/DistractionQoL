-- ItemCounts.lua
-- Dedicated item tooltip inventory breakdown & crafting reagent expansion module for DistractionQoL
-- Displays item counts across Bags, Personal Bank, and Warband Bank (Account Bank)
-- Displays Crafting Reagent Expansion tag with current-content highlighting
-- Fast, event-driven, zero polling, zero continuous OnUpdate
-- Uses modern TooltipDataProcessor API (WoW 11.x / 12.1+ Midnight)

local addonName, DQ = ...

DQ.ItemCounts = {}

-- UI Color Palette
local COLOR_HEADER  = "|cff00e5ff" -- Cyan
local COLOR_BAGS    = "|cff00e5ff" -- Cyan
local COLOR_BANK    = "|cffffcc00" -- Yellow/Amber
local COLOR_WARBAND = "|cffb19cd9" -- Soft Lavender/Purple
local COLOR_TOTAL   = "|cffffffff" -- White
local COLOR_MUTED   = "|cff888888" -- Grey
local COLOR_CURRENT = "|cffffd100" -- Gold

-- Scans bank bags and persists counts into DistractionQoLDB.bankCache
local function ScanBankBags()
    if not DistractionQoLDB then return end
    DistractionQoLDB.bankCache = DistractionQoLDB.bankCache or { character = {}, warband = {} }
    local cache = DistractionQoLDB.bankCache
    cache.character = cache.character or {}
    cache.warband = cache.warband or {}

    -- Character bank bags (CharacterBankTab_1..9, Bank -1, Reagentbank -3, BankBag_1..7)
    local charBags = {}
    if Enum and Enum.BagIndex then
        for i = 1, 9 do
            local key = "CharacterBankTab_" .. i
            if Enum.BagIndex[key] then table.insert(charBags, Enum.BagIndex[key]) end
        end
        if Enum.BagIndex.Bank then table.insert(charBags, Enum.BagIndex.Bank) end
        if Enum.BagIndex.Reagentbank then table.insert(charBags, Enum.BagIndex.Reagentbank) end
        for i = 1, 7 do
            local key = "BankBag_" .. i
            if Enum.BagIndex[key] then table.insert(charBags, Enum.BagIndex[key]) end
        end
    else
        charBags = { -1, -3, 6, 7, 8, 9, 10, 11, 12 }
    end

    local tempChar = {}
    for _, bagID in ipairs(charBags) do
        local numSlots = (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bagID)) or 0
        for slot = 1, numSlots do
            local itemID = C_Container.GetContainerItemID(bagID, slot)
            if itemID then
                local info = C_Container.GetContainerItemInfo(bagID, slot)
                local stack = (info and info.stackCount) or 1
                tempChar[itemID] = (tempChar[itemID] or 0) + stack
            end
        end
    end
    if next(tempChar) then
        cache.character = tempChar
    end

    -- Warband bank bags (AccountBankTab_1..5)
    local warbandBags = {}
    if Enum and Enum.BagIndex then
        for i = 1, 5 do
            local key = "AccountBankTab_" .. i
            if Enum.BagIndex[key] then table.insert(warbandBags, Enum.BagIndex[key]) end
        end
    end

    if #warbandBags > 0 then
        local tempWarband = {}
        for _, bagID in ipairs(warbandBags) do
            local numSlots = (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bagID)) or 0
            for slot = 1, numSlots do
                local itemID = C_Container.GetContainerItemID(bagID, slot)
                if itemID then
                    local info = C_Container.GetContainerItemInfo(bagID, slot)
                    local stack = (info and info.stackCount) or 1
                    tempWarband[itemID] = (tempWarband[itemID] or 0) + stack
                end
            end
        end
        if next(tempWarband) then
            cache.warband = tempWarband
        end
    end
end

-- Retrieves item count breakdown across Bags, Personal Bank, and Warband Bank
local function GetItemBreakdown(itemID)
    local bags = (C_Item and C_Item.GetItemCount and C_Item.GetItemCount(itemID, false, false, false, false)) or 0
    local withBank = (C_Item and C_Item.GetItemCount and C_Item.GetItemCount(itemID, true, false, false, false)) or 0
    local bank = math.max(0, withBank - bags)
    local withReagent = (C_Item and C_Item.GetItemCount and C_Item.GetItemCount(itemID, true, false, true, false)) or 0
    local reagent = math.max(0, withReagent - withBank)
    local withWarband = (C_Item and C_Item.GetItemCount and C_Item.GetItemCount(itemID, true, false, true, true)) or 0
    local warband = math.max(0, withWarband - withReagent)

    -- If bank was never visited in this session, native C_Item.GetItemCount returns 0 for bank & warband.
    -- In that scenario, smoothly fall back to our saved bankCache!
    local cache = DistractionQoLDB and DistractionQoLDB.bankCache
    if (bank == 0 and warband == 0 and reagent == 0) and cache then
        if cache.character and cache.character[itemID] then
            bank = cache.character[itemID]
        end
        if cache.warband and cache.warband[itemID] then
            warband = cache.warband[itemID]
        end
    end

    local total = bags + bank + reagent + warband
    return bags, (bank + reagent), warband, total
end

-- Checks if the item is a crafting reagent and determines its originating expansion
local function GetReagentExpansionInfo(itemID, itemLink)
    local target = itemLink or itemID
    if not target then return nil end

    local _, _, _, _, _, classID, subclassID, _, _, _, _, _, _, _, expacID, _, isCraftingReagent = C_Item.GetItemInfo(target)
    
    local isReagent = isCraftingReagent
    if not isReagent and classID and Enum and Enum.ItemClass then
        if classID == Enum.ItemClass.Tradegoods or classID == Enum.ItemClass.Profession then
            isReagent = true
        end
    end

    if not isReagent or expacID == nil then
        return nil
    end

    -- Localized expansion name resolution
    local expacName
    if expacID == 254 or expacID == 255 then
        expacName = _G["EXPANSION_NAME0"] or "Classic"
    elseif expacID == 11 or (LE_EXPANSION_MIDNIGHT and expacID == LE_EXPANSION_MIDNIGHT) then
        expacName = _G["EXPANSION_NAME11"] or "Midnight"
    else
        expacName = _G["EXPANSION_NAME" .. expacID]
    end

    if not expacName or expacName == "" then
        expacName = "Expansion " .. tostring(expacID)
    end

    -- Determine if current retail expansion (Midnight 12.x)
    local currentExpac = (GetExpansionLevel and GetExpansionLevel()) or LE_EXPANSION_MIDNIGHT or 11
    local isCurrent = (expacID == currentExpac)

    return expacName, isCurrent, expacID
end

-- Tooltip post-call handler
local function OnTooltipSetItem(tooltip, data)
    if not tooltip then return end

    -- Extract itemID
    local itemID = data and data.id
    local itemLink = nil
    if not itemID then
        local _, link = tooltip:GetItem()
        if link then
            itemLink = link
            itemID = C_Item.GetItemInfoInstant and C_Item.GetItemInfoInstant(link)
        end
    end

    if not itemID then return end

    local cfg = DQ.Config and DQ.Config:Get("tooltip")
    if not cfg then return end

    local countCfg = cfg.itemCount
    local expacCfg = cfg.reagentExpansion
    local L = DQ.L or {}

    -- 1. Crafting Reagent Expansion Tag
    if expacCfg and expacCfg.enabled then
        local expacName, isCurrent = GetReagentExpansionInfo(itemID, itemLink)
        if expacName then
            local label = L["TOOLTIP_EXPANSION_LABEL"] or "Expansión:"
            local valText
            if isCurrent then
                valText = string.format("%s%s %s(%s)|r", COLOR_CURRENT, expacName, "|cffffd100", L["EXPANSION_CURRENT"] or "Actual")
            else
                valText = string.format("%s%s %s(%s)|r", COLOR_MUTED, expacName, "|cff888888", L["EXPANSION_LEGACY"] or "Antiguo")
            end
            tooltip:AddDoubleLine(COLOR_HEADER .. label .. "|r", valText)
        end
    end

    -- 2. Inventory Breakdown (Bags / Personal Bank / Warband Bank)
    if countCfg and countCfg.enabled then
        if not countCfg.requireShift or IsShiftKeyDown() then
            local bags, bank, warband, total = GetItemBreakdown(itemID)

            -- Filter: hide single item if only 1 in bags and 0 in bank/warband
            local shouldShow = true
            if countCfg.hideSingle and total <= 1 and (bank == 0 and warband == 0) then
                shouldShow = false
            end

            if shouldShow and total > 0 then
                tooltip:AddLine(" ")
                tooltip:AddLine(COLOR_HEADER .. (L["TOOLTIP_INVENTORY_HEADER"] or "Inventario:") .. "|r")

                local hasShownComponent = false
                if countCfg.showBags and bags > 0 then
                    tooltip:AddDoubleLine("  " .. (L["TOOLTIP_BAGS"] or "Bolsas:"), string.format("%s%d|r", COLOR_BAGS, bags), 0.85, 0.85, 0.85)
                    hasShownComponent = true
                end
                if countCfg.showBank and bank > 0 then
                    tooltip:AddDoubleLine("  " .. (L["TOOLTIP_BANK"] or "Banco:"), string.format("%s%d|r", COLOR_BANK, bank), 0.85, 0.85, 0.85)
                    hasShownComponent = true
                end
                if countCfg.showWarband and warband > 0 then
                    tooltip:AddDoubleLine("  " .. (L["TOOLTIP_WARBAND"] or "Banda Guerrera:"), string.format("%s%d|r", COLOR_WARBAND, warband), 0.85, 0.85, 0.85)
                    hasShownComponent = true
                end
                if countCfg.showTotal and (hasShownComponent or total > 0) then
                    tooltip:AddDoubleLine("  " .. (L["TOOLTIP_TOTAL"] or "Total:"), string.format("%s%d|r", COLOR_TOTAL, total), 0.95, 0.95, 0.95)
                end
            end
        end
    end
end

function DQ.ItemCounts:Init()
    -- Bank event watcher for caching
    local bankWatcher = CreateFrame("Frame")
    bankWatcher:RegisterEvent("BANKFRAME_OPENED")
    bankWatcher:RegisterEvent("BANKFRAME_CLOSED")
    bankWatcher:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
    bankWatcher:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")

    bankWatcher:SetScript("OnEvent", function(self, event, arg1)
        if event == "BANKFRAME_OPENED" or event == "BANKFRAME_CLOSED" then
            ScanBankBags()
        elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" or event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
            -- Banker = 8, AccountBanker = 60
            if arg1 == 8 or arg1 == 60 or (Enum and Enum.PlayerInteractionType and (arg1 == Enum.PlayerInteractionType.Banker or arg1 == Enum.PlayerInteractionType.AccountBanker)) then
                ScanBankBags()
            end
        end
    end)

    -- Live modifier watcher: pressing SHIFT while hovering an item immediately refreshes the tooltip
    local modWatcher = CreateFrame("Frame")
    modWatcher:RegisterEvent("MODIFIER_STATE_CHANGED")
    modWatcher:SetScript("OnEvent", function(_, key)
        if key == "LSHIFT" or key == "RSHIFT" then
            local cfg = DQ.Config and DQ.Config:Get("tooltip", "itemCount")
            if cfg and cfg.requireShift then
                if GameTooltip and GameTooltip:IsShown() and GameTooltip.RefreshData then
                    GameTooltip:RefreshData()
                elseif ItemRefTooltip and ItemRefTooltip:IsShown() and ItemRefTooltip.RefreshData then
                    ItemRefTooltip:RefreshData()
                end
            end
        end
    end)

    -- Modern WoW 11.x / 12.1+ TooltipDataProcessor API
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
    elseif GameTooltip then
        GameTooltip:HookScript("OnTooltipSetItem", function(self)
            OnTooltipSetItem(self, nil)
        end)
        if ItemRefTooltip then
            ItemRefTooltip:HookScript("OnTooltipSetItem", function(self)
                OnTooltipSetItem(self, nil)
            end)
        end
    end
end
