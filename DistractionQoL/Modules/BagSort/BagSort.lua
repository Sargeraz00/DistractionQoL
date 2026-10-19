-- BagSort.lua
-- Reverse Bag Sorting & Automated Profession Reagent Stashing Module for DistractionQoL
-- Fully updated for WoW 12.1.5 (Midnight)
-- 1. Moves crafting & profession reagents into the Reagent Bag (Bag 5).
-- 2. Places overflow reagents at the TOP of regular bags (Bag 0, Slot 1 downwards).
-- 3. Places all other items (gear, consumables, quest, junk) at the BOTTOM (inversely to Blizzard).
-- 4. Pure event-driven, safe asynchronous queue, zero taint, zero combat execution.

local addonName, DQ = ...

DQ.BagSort = {}

local queue = {
    actions = {},
    isProcessing = false,
    ticker = nil,
    stuckTicks = 0,
}

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

-- Checks if a slot is currently locked by server transaction
local function IsSlotLocked(bag, slot)
    if not C_Container or not C_Container.GetContainerItemInfo then return false end
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if info and type(info) == "table" then
        return info.isLocked == true
    end
    return false
end

-- Accurately identifies if an item is a profession/crafting reagent (WoW 12.1.5 compatible)
local function IsCraftingReagent(itemID, hyperlink)
    if not itemID and not hyperlink then return false end

    -- 1. Modern C_Item API check (17th return value is isCraftingReagent)
    if C_Item and C_Item.GetItemInfo then
        local _, _, _, _, _, _, _, _, _, _, _, classID, _, _, _, _, isCraftingReagent = C_Item.GetItemInfo(hyperlink or itemID)
        if isCraftingReagent == true then
            return true
        end
        if classID == 7 or (Enum.ItemClass and classID == Enum.ItemClass.Tradegoods) then
            return true
        end
    end

    -- 2. Fast instant lookup fallback
    if C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemID or hyperlink)
        if classID == 7 or (Enum.ItemClass and classID == Enum.ItemClass.Tradegoods) then
            return true
        end
    end

    return false
end
DQ.BagSort.IsCraftingReagent = IsCraftingReagent

-- Computes sorting weight for non-reagent items to place at the bottom of the bags
-- Priority order: Equipment -> Consumables -> Miscellaneous -> Grey Junk at the very bottom
local function GetItemSortWeight(item)
    if not item then return 0 end
    local quality = item.quality or 1

    -- Grey junk items (quality 0) go to the absolute bottom-most slots
    if quality == 0 then
        return 900000 + (item.itemID or 0)
    end

    local classID = 15 -- Default Misc
    if C_Item and C_Item.GetItemInfoInstant and item.itemID then
        local _, _, _, _, _, cID = C_Item.GetItemInfoInstant(item.itemID)
        if cID then classID = cID end
    end

    local classWeight = 500000
    if classID == 2 or classID == 4 then
        -- Weapons and Armor
        classWeight = 100000
    elseif classID == 0 then
        -- Consumables (Potions, Flasks, Food)
        classWeight = 200000
    elseif classID == 3 or classID == 8 then
        -- Gems, Item Enhancements
        classWeight = 300000
    elseif classID == 12 or classID == 15 then
        -- Quest, Miscellaneous
        classWeight = 400000
    end

    -- Invert quality so higher quality items are placed higher within the bottom group
    local qualityFactor = (7 - quality) * 10000
    return classWeight + qualityFactor
end

-- Checks if the sort queue is actively processing
function DQ.BagSort:IsSorting()
    return queue.isProcessing
end

-- Clears and stops any pending sorting actions safely
function DQ.BagSort:StopSorting()
    if queue.ticker then
        queue.ticker:Cancel()
        queue.ticker = nil
    end
    queue.actions = {}
    queue.isProcessing = false
    queue.stuckTicks = 0
    if CursorHasItem and CursorHasItem() and ClearCursor then
        ClearCursor()
    end
end

-- Asynchronous queue processor using safe interval ticks
local function StartQueueProcessing()
    if queue.isProcessing then return end
    queue.isProcessing = true
    queue.stuckTicks = 0

    local L = DQ.L or {}

    queue.ticker = C_Timer.NewTicker(0.04, function()
        -- 1. Safety check: Combat lockdown aborts bag movement immediately to prevent UI taint
        if InCombatLockdown and InCombatLockdown() then
            DQ.BagSort:StopSorting()
            PrintMsg(L["MSG_BAG_SORT_COMBAT"] or "|cffff3333No se pueden ordenar las bolsas durante el combate.|r")
            return
        end

        -- 2. Check if all actions completed
        if #queue.actions == 0 then
            DQ.BagSort:StopSorting()
            if PlaySound then
                pcall(PlaySound, SOUNDKIT.IG_BACKPACK_OPEN or 862, "SFX")
            end
            PrintMsg(L["MSG_BAG_SORT_COMPLETE"] or "¡Bolsas organizadas con éxito! Materiales en bolsa de profesión, excedente arriba y resto abajo.")
            return
        end

        -- 3. Cursor safety: Wait if cursor is holding an item
        if CursorHasItem and CursorHasItem() then
            queue.stuckTicks = queue.stuckTicks + 1
            if queue.stuckTicks > 20 then
                -- Stuck cursor safety release
                if ClearCursor then ClearCursor() end
                queue.stuckTicks = 0
            end
            return
        end

        local action = queue.actions[1]

        -- 4. Verify source and destination are unlocked by server
        local sourceLocked = IsSlotLocked(action.fromBag, action.fromSlot)
        local destLocked = IsSlotLocked(action.toBag, action.toSlot)

        if not sourceLocked and not destLocked then
            queue.stuckTicks = 0
            -- Execute safe pickup & swap
            if C_Container and C_Container.PickupContainerItem then
                C_Container.PickupContainerItem(action.fromBag, action.fromSlot)
                C_Container.PickupContainerItem(action.toBag, action.toSlot)
                if CursorHasItem and CursorHasItem() then
                    C_Container.PickupContainerItem(action.fromBag, action.fromSlot)
                end
            end

            -- Remove executed action
            table.remove(queue.actions, 1)
        else
            queue.stuckTicks = queue.stuckTicks + 1
            if queue.stuckTicks > 25 then
                -- Timeout safeguard: skip unmovable item to prevent deadlock
                table.remove(queue.actions, 1)
                queue.stuckTicks = 0
            end
        end
    end)
end

local function ExecuteBagSortInternal()
    local L = DQ.L or {}

    -- Guard 1: Combat lockdown
    if InCombatLockdown and InCombatLockdown() then
        PrintMsg(L["MSG_BAG_SORT_COMBAT"] or "|cffff3333No se pueden ordenar las bolsas durante el combate.|r")
        return
    end

    -- Guard 2: Cursor item
    if CursorHasItem and CursorHasItem() then
        PrintMsg(L["MSG_BAG_SORT_CURSOR"] or "|cffffaa00Por favor suelta el objeto del cursor antes de ordenar.|r")
        return
    end

    -- Guard 3: Already sorting
    if queue.isProcessing then
        PrintMsg(L["MSG_BAG_SORT_BUSY"] or "|cffffcc00Ya hay un ordenamiento de bolsas en progreso...|r")
        return
    end

    if not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerItemInfo then
        return
    end

    -- Step 1: Scan all slots and items across Bags 0..5
    local inventory = {}
    for bag = 0, 5 do
        inventory[bag] = {}
    end

    -- Regular bag slots: Bags 0 to 4 (Top to Bottom order)
    local regularSlots = {}
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            table.insert(regularSlots, { bag = bag, slot = slot })
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local isReagent = IsCraftingReagent(info.itemID, info.hyperlink)
                local itemData = {
                    bag = bag,
                    slot = slot,
                    itemID = info.itemID,
                    hyperlink = info.hyperlink,
                    quality = info.quality or 1,
                    stackCount = info.stackCount or 1,
                    isReagent = isReagent,
                    name = (info.hyperlink and info.hyperlink:match("%[(.-)%]")) or tostring(info.itemID),
                    uid = string.format("%d:%d", bag, slot),
                }
                inventory[bag][slot] = itemData
            end
        end
    end

    -- Reagent Bag slots: Bag 5
    local reagentBagSlots = {}
    local numReagentSlots = C_Container.GetContainerNumSlots(5) or 0
    for slot = 1, numReagentSlots do
        table.insert(reagentBagSlots, { bag = 5, slot = slot })
        local info = C_Container.GetContainerItemInfo(5, slot)
        if info and info.itemID then
            local isReagent = IsCraftingReagent(info.itemID, info.hyperlink)
            local itemData = {
                bag = 5,
                slot = slot,
                itemID = info.itemID,
                hyperlink = info.hyperlink,
                quality = info.quality or 1,
                stackCount = info.stackCount or 1,
                isReagent = isReagent,
                name = (info.hyperlink and info.hyperlink:match("%[(.-)%]")) or tostring(info.itemID),
                uid = string.format("%d:%d", 5, slot),
            }
            inventory[5][slot] = itemData
        end
    end

    -- Step 2: Generate optimal movement plan via pure BagSortLogic
    local actions = DQ.BagSortLogic and DQ.BagSortLogic.GeneratePlan
        and DQ.BagSortLogic.GeneratePlan(inventory, regularSlots, reagentBagSlots) or {}

    -- Step 5: Check if any moves were required
    if #actions == 0 then
        PrintMsg(L["MSG_BAG_SORT_ALREADY_SORTED"] or "Las bolsas ya están ordenadas correctamente.")
        return
    end

    -- Step 6: Enqueue and start asynchronous execution
    queue.actions = actions
    PrintMsg(string.format(L["MSG_BAG_SORT_START"] or "Iniciando ordenamiento inverso de bolsas (%d movimientos)...", #actions))
    StartQueueProcessing()
end

-- Public SortBags with intelligent conflict resolution
function DQ.BagSort:SortBags()
    if DQ.ConflictResolver and DQ.ConflictResolver.CheckAndExecute then
        DQ.ConflictResolver:CheckAndExecute("bagSort", function()
            ExecuteBagSortInternal()
        end, function()
            -- External Addon Sort fallback
            if _G["EUI_Bags"] and _G["EUI_Bags"]._doVisualSort then
                _G["EUI_Bags"]._doVisualSort()
            elseif C_Container and C_Container.SortBags then
                C_Container.SortBags()
            end
        end)
    else
        ExecuteBagSortInternal()
    end
end

-- ==========================================================
-- UI BUTTON INTEGRATION (NATIVE BAG HEADER & ELLESMEREUI)
-- ==========================================================
local sortBtn = nil
local originalEUISortOnClick = nil
local originalEUISortOnEnter = nil

-- Helper to safely find the active native sort button (combined or individual bags)
local function GetSortAnchor()
    if _G["BagItemAutoSortButton"] and _G["BagItemAutoSortButton"]:IsShown() then
        return _G["BagItemAutoSortButton"]
    end
    if ContainerFrameCombinedBags and ContainerFrameCombinedBags.BagItemAutoSortButton and ContainerFrameCombinedBags.BagItemAutoSortButton:IsShown() then
        return ContainerFrameCombinedBags.BagItemAutoSortButton
    end
    if ContainerFrame1 and ContainerFrame1.BagItemAutoSortButton and ContainerFrame1.BagItemAutoSortButton:IsShown() then
        return ContainerFrame1.BagItemAutoSortButton
    end
    return _G["BagItemAutoSortButton"]
end

local function HookSortAnchor(anchor)
    if not anchor or anchor._DQHooked then return end
    anchor._DQHooked = true

    anchor:HookScript("OnShow", function()
        DQ.BagSort:UpdateBagButtonVisibility()
    end)
    anchor:HookScript("OnHide", function()
        if sortBtn and not (_G["EUI_Bags"] and _G["EUI_Bags"]:IsShown()) then
            sortBtn:Hide()
        end
    end)
    if hooksecurefunc then
        hooksecurefunc(anchor, "SetPoint", function()
            DQ.BagSort:UpdateBagButtonVisibility()
        end)
        hooksecurefunc(anchor, "SetParent", function()
            DQ.BagSort:UpdateBagButtonVisibility()
        end)
    end
end

-- ==========================================================
-- ELLESMEREUI BAGS INTEGRATION
-- ==========================================================

local function IsEllesmereBagsLoaded()
    return _G["EUI_Bags"] ~= nil and _G["EUI_Bags"]._sortBtn ~= nil
end

function DQ.BagSort:UpdateEllesmereIntegration()
    if not IsEllesmereBagsLoaded() then return end

    local euiSortBtn = _G["EUI_Bags"]._sortBtn
    if not euiSortBtn then return end

    -- Capture original native scripts before any DistractionQoL modifications
    if not originalEUISortOnClick and euiSortBtn:GetScript("OnClick") then
        local currentClick = euiSortBtn:GetScript("OnClick")
        if currentClick ~= DQ.BagSort._dqSortOnClick then
            originalEUISortOnClick = currentClick
        end
    end
    if not originalEUISortOnEnter and euiSortBtn:GetScript("OnEnter") then
        local currentEnter = euiSortBtn:GetScript("OnEnter")
        if currentEnter ~= DQ.BagSort._dqSortOnEnter then
            originalEUISortOnEnter = currentEnter
        end
    end

    local conflictChoice = (DQ.ConflictResolver and DQ.ConflictResolver.GetChoice and DQ.ConflictResolver:GetChoice("bagSort"))
    local shouldOverride = DQ.Config:Get("automation", "overrideEllesmereSort") ~= false
    local enabled = DQ.Config:Get("automation", "bagSortButton") ~= false

    if conflictChoice == "External" or conflictChoice == "Disabled" or not enabled or not shouldOverride then
        -- Ceded to EllesmereUI or Disabled: Restore EllesmereUI's native OnClick and OnEnter
        if originalEUISortOnClick then
            euiSortBtn:SetScript("OnClick", originalEUISortOnClick)
        end
        if originalEUISortOnEnter then
            euiSortBtn:SetScript("OnEnter", originalEUISortOnEnter)
        end
        if sortBtn then sortBtn:Hide() end
        return
    end

    -- DistractionQoL is actively managing bag sort: Override Ellesmere button
    DQ.BagSort._dqSortOnClick = function()
        DQ.BagSort:SortBags()
    end
    euiSortBtn:SetScript("OnClick", DQ.BagSort._dqSortOnClick)

    DQ.BagSort._dqSortOnEnter = function(btn)
        local L = DQ.L or {}
        GameTooltip:SetOwner(btn, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine(L["BAG_SORT_TITLE"] or "|cff00e5ffDistractionQoL - Orden Inverso & Materiales|r")
        GameTooltip:AddLine(L["BAG_SORT_DESC_1"] or "|cffffcc001.|r Mueve materiales de profesión a la bolsa de materiales (Bag 5).", 1, 1, 1)
        GameTooltip:AddLine(L["BAG_SORT_DESC_2"] or "|cffffcc002.|r Si sobran materiales, los coloca arriba del todo.", 1, 1, 1)
        GameTooltip:AddLine(L["BAG_SORT_DESC_3"] or "|cffffcc003.|r Resto de objetos (equipo, consumibles) van abajo del todo.", 1, 1, 1)
        GameTooltip:AddLine("|cff00ff00Clic para ordenar bolsas (Modo DistractionQoL).|r", 0.2, 1, 0.2)
        GameTooltip:Show()
    end
    euiSortBtn:SetScript("OnEnter", DQ.BagSort._dqSortOnEnter)

    if sortBtn then
        sortBtn:Hide()
    end
end

local function UpdateButtonAnchor()
    local conflictChoice = (DQ.ConflictResolver and DQ.ConflictResolver.GetChoice and DQ.ConflictResolver:GetChoice("bagSort"))
    if conflictChoice == "Disabled" then
        if sortBtn then sortBtn:Hide() end
        return
    end

    if IsEllesmereBagsLoaded() then
        DQ.BagSort:UpdateEllesmereIntegration()
        if conflictChoice == "External" or DQ.Config:Get("automation", "overrideEllesmereSort") ~= false then
            return
        end
    end

    if not sortBtn then return end

    local enabled = DQ.Config:Get("automation", "bagSortButton")
    if enabled == false then
        sortBtn:Hide()
        return
    end

    if IsEllesmereBagsLoaded() and _G["EUI_Bags"]:IsShown() then
        return
    end

    local anchorTarget = GetSortAnchor()
    if anchorTarget then
        HookSortAnchor(anchorTarget)
    end

    if not anchorTarget or not anchorTarget:IsShown() then
        sortBtn:Hide()
        return
    end

    local parent = anchorTarget:GetParent() or ContainerFrameCombinedBags or UIParent
    sortBtn:SetParent(parent)
    sortBtn:ClearAllPoints()
    sortBtn:SetPoint("RIGHT", anchorTarget, "LEFT", -3, 0)
    sortBtn:SetFrameLevel((anchorTarget:GetFrameLevel() or 10) + 1)
    sortBtn:Show()
end

function DQ.BagSort:UpdateBagButtonVisibility()
    UpdateButtonAnchor()
end

local function CreateBagSortButton()
    if sortBtn then return sortBtn end

    sortBtn = CreateFrame("Button", "DistractionQoLBagSortButton", UIParent, "BackdropTemplate")
    sortBtn:SetSize(22, 22)
    sortBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    sortBtn:SetBackdropColor(0.10, 0.10, 0.14, 0.95)
    sortBtn:SetBackdropBorderColor(0.0, 0.75, 0.90, 0.8)

    local icon = sortBtn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", -2, 2)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    sortBtn.icon = icon

    sortBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.0, 1.0, 1.0, 1)
        self:SetBackdropColor(0.18, 0.18, 0.25, 1)

        local L = DQ.L or {}
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine(L["BAG_SORT_TITLE"] or "|cff00e5ffDistractionQoL - Orden Inverso & Materiales|r")
        GameTooltip:AddLine(L["BAG_SORT_DESC_1"] or "|cffffcc001.|r Mueve materiales de profesión a la bolsa de materiales.", 1, 1, 1)
        GameTooltip:AddLine(L["BAG_SORT_DESC_2"] or "|cffffcc002.|r Si sobran materiales, los coloca arriba del todo.", 1, 1, 1)
        GameTooltip:AddLine(L["BAG_SORT_DESC_3"] or "|cffffcc003.|r Resto de objetos (equipo, consumibles) van abajo del todo.", 1, 1, 1)
        GameTooltip:AddLine(L["BAG_SORT_CLICK"] or "|cff00ff00Clic para ordenar bolsas.|r", 0.2, 1, 0.2)
        GameTooltip:Show()
    end)

    sortBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.0, 0.75, 0.90, 0.8)
        self:SetBackdropColor(0.10, 0.10, 0.14, 0.95)
        GameTooltip:Hide()
    end)

    sortBtn:SetScript("OnClick", function(self)
        DQ.BagSort:SortBags()
    end)

    sortBtn:Hide()
    return sortBtn
end

-- Initializes event handlers and bag button hooks
function DQ.BagSort:Init()
    CreateBagSortButton()

    -- 1. Native Blizzard Hooks
    local anchorTarget = GetSortAnchor()
    if anchorTarget then
        HookSortAnchor(anchorTarget)
    end

    if ContainerFrameCombinedBags and ContainerFrameCombinedBags.HookScript then
        ContainerFrameCombinedBags:HookScript("OnShow", function()
            C_Timer.After(0.02, UpdateButtonAnchor)
        end)
    end

    if hooksecurefunc then
        if ToggleAllBags then
            hooksecurefunc("ToggleAllBags", function()
                C_Timer.After(0.02, UpdateButtonAnchor)
            end)
        end
        if OpenAllBags then
            hooksecurefunc("OpenAllBags", function()
                C_Timer.After(0.02, UpdateButtonAnchor)
            end)
        end
        if ToggleBackpack then
            hooksecurefunc("ToggleBackpack", function()
                C_Timer.After(0.02, UpdateButtonAnchor)
            end)
        end
        if OpenBackpack then
            hooksecurefunc("OpenBackpack", function()
                C_Timer.After(0.02, UpdateButtonAnchor)
            end)
        end
    end

    -- 2. EllesmereUI Hooks
    local function TryHookEllesmere()
        if _G["EUI_Bags"] then
            if _G["EUI_Bags"].SyncHeaderIcons and not _G["EUI_Bags"]._dqSyncHooked then
                _G["EUI_Bags"]._dqSyncHooked = true
                hooksecurefunc(_G["EUI_Bags"], "SyncHeaderIcons", function()
                    C_Timer.After(0.02, function()
                        DQ.BagSort:UpdateEllesmereIntegration()
                    end)
                end)
            end
            if not _G["EUI_Bags"]._dqShowHooked then
                _G["EUI_Bags"]._dqShowHooked = true
                _G["EUI_Bags"]:HookScript("OnShow", function()
                    C_Timer.After(0.02, function()
                        DQ.BagSort:UpdateEllesmereIntegration()
                    end)
                end)
                _G["EUI_Bags"]:HookScript("OnHide", function()
                    if sortBtn and sortBtn:GetParent() == (_G["EUI_Bags"]._sortBtn and _G["EUI_Bags"]._sortBtn:GetParent()) then
                        sortBtn:Hide()
                    end
                end)
            end
            DQ.BagSort:UpdateEllesmereIntegration()
        end
    end

    TryHookEllesmere()

    -- 3. Event Frame
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    eventFrame:SetScript("OnEvent", function(self, event, arg1)
        if event == "ADDON_LOADED" and arg1 == "EllesmereUIBags" then
            TryHookEllesmere()
        else
            UpdateButtonAnchor()
        end
    end)

    self.eventFrame = eventFrame
end

-- Reactive Config subscriptions
if DQ.Config and DQ.Config.RegisterCallback then
    DQ.Config:RegisterCallback("automation.bagSortButton", function()
        if DQ.BagSort and DQ.BagSort.UpdateBagButtonVisibility then
            DQ.BagSort:UpdateBagButtonVisibility()
        end
    end)
    DQ.Config:RegisterCallback("automation.overrideEllesmereSort", function()
        if DQ.BagSort and DQ.BagSort.UpdateEllesmereIntegration then
            DQ.BagSort:UpdateEllesmereIntegration()
        end
    end)
end
