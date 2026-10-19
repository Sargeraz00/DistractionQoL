-- BagSortLogic.lua
-- Pure business logic for Reverse Bag Sorting & Reagent Stashing
-- Calculates optimized movement plans (actions) given an inventory matrix.
-- Decoupled from WoW Frame/UI tickers for clean offline testability.

local addonName, DQ = ...

DQ.BagSortLogic = {}

-- Identifies if an item is a profession/crafting reagent
function DQ.BagSortLogic.IsCraftingReagent(itemID, hyperlink)
    if not itemID and not hyperlink then return false end

    -- Modern C_Item API check (17th return value is isCraftingReagent)
    if C_Item and C_Item.GetItemInfo then
        local _, _, _, _, _, _, _, _, _, _, _, classID, _, _, _, _, isCraftingReagent = C_Item.GetItemInfo(hyperlink or itemID)
        if isCraftingReagent == true then
            return true
        end
        if classID == 7 or (Enum.ItemClass and classID == Enum.ItemClass.Tradegoods) then
            return true
        end
    end

    -- Fast instant lookup fallback
    if C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemID or hyperlink)
        if classID == 7 or (Enum.ItemClass and classID == Enum.ItemClass.Tradegoods) then
            return true
        end
    end

    return false
end

-- Computes sorting weight for non-reagent items to place at the bottom of the bags
function DQ.BagSortLogic.GetItemSortWeight(item)
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

-- Calculates the complete movement plan given an inventory snapshot
function DQ.BagSortLogic.GeneratePlan(inventory, regularSlots, reagentBagSlots)
    local actions = {}
    local numReagentSlots = #reagentBagSlots

    -- Step 1: Move reagents from regular bags (0..4) into empty slots of Reagent Bag (5)
    if numReagentSlots > 0 then
        local emptySlotsBag5 = {}
        for s = 1, numReagentSlots do
            if not inventory[5][s] then
                table.insert(emptySlotsBag5, { bag = 5, slot = s })
            end
        end

        local regReagents = {}
        for _, slotCoord in ipairs(regularSlots) do
            local item = inventory[slotCoord.bag][slotCoord.slot]
            if item and item.isReagent then
                table.insert(regReagents, item)
            end
        end

        for _, item in ipairs(regReagents) do
            if #emptySlotsBag5 == 0 then break end
            local dest = table.remove(emptySlotsBag5, 1)

            table.insert(actions, {
                fromBag = item.bag,
                fromSlot = item.slot,
                toBag = dest.bag,
                toSlot = dest.slot,
            })

            -- Update virtual map
            inventory[dest.bag][dest.slot] = item
            inventory[item.bag][item.slot] = nil
            item.bag = dest.bag
            item.slot = dest.slot
        end
    end

    -- Step 2: Plan and sort Reagent Bag (5) internally
    if numReagentSlots > 0 then
        local itemsIn5 = {}
        for s = 1, numReagentSlots do
            if inventory[5][s] then
                table.insert(itemsIn5, inventory[5][s])
            end
        end

        table.sort(itemsIn5, function(a, b)
            if a.quality ~= b.quality then
                return a.quality > b.quality
            end
            if a.name ~= b.name then
                return a.name < b.name
            end
            return (a.stackCount or 1) > (b.stackCount or 1)
        end)

        for targetIndex, targetItem in ipairs(itemsIn5) do
            local currentSlot = nil
            for s = 1, numReagentSlots do
                if inventory[5][s] == targetItem then
                    currentSlot = s
                    break
                end
            end

            if currentSlot and currentSlot ~= targetIndex then
                table.insert(actions, {
                    fromBag = 5,
                    fromSlot = currentSlot,
                    toBag = 5,
                    toSlot = targetIndex,
                })

                inventory[5][currentSlot], inventory[5][targetIndex] = inventory[5][targetIndex], inventory[5][currentSlot]
            end
        end
    end

    -- Step 3: Plan and sort Regular Bags (0..4)
    local overflowReagents = {}
    local otherItems = {}

    for _, slotCoord in ipairs(regularSlots) do
        local item = inventory[slotCoord.bag][slotCoord.slot]
        if item then
            if item.isReagent then
                table.insert(overflowReagents, item)
            else
                table.insert(otherItems, item)
            end
        end
    end

    -- Sort overflow reagents: Quality DESC, Name ASC
    table.sort(overflowReagents, function(a, b)
        if a.quality ~= b.quality then
            return a.quality > b.quality
        end
        if a.name ~= b.name then
            return a.name < b.name
        end
        return (a.stackCount or 1) > (b.stackCount or 1)
    end)

    -- Sort other items: SortWeight ASC (Equipment -> Consumables -> Misc -> Junk)
    table.sort(otherItems, function(a, b)
        local wA = DQ.BagSortLogic.GetItemSortWeight(a)
        local wB = DQ.BagSortLogic.GetItemSortWeight(b)
        if wA ~= wB then
            return wA < wB
        end
        if a.quality ~= b.quality then
            return a.quality > b.quality
        end
        return a.name < b.name
    end)

    local totalRegSlots = #regularSlots
    local targetAssignments = {}

    -- Overflow reagents to TOP of regular bags (1..K)
    for i, rItem in ipairs(overflowReagents) do
        table.insert(targetAssignments, {
            targetSlot = regularSlots[i],
            item = rItem,
        })
    end

    -- Other items to BOTTOM of regular bags
    local startOtherIdx = totalRegSlots - #otherItems + 1
    for i, oItem in ipairs(otherItems) do
        local targetSlotIdx = startOtherIdx + i - 1
        table.insert(targetAssignments, {
            targetSlot = regularSlots[targetSlotIdx],
            item = oItem,
        })
    end

    -- Execute permutation swaps on regular bags
    for _, assignment in ipairs(targetAssignments) do
        local targetSlot = assignment.targetSlot
        local desiredItem = assignment.item

        local curBag, curSlot = nil, nil
        for _, slotCoord in ipairs(regularSlots) do
            if inventory[slotCoord.bag][slotCoord.slot] == desiredItem then
                curBag = slotCoord.bag
                curSlot = slotCoord.slot
                break
            end
        end

        if curBag and (curBag ~= targetSlot.bag or curSlot ~= targetSlot.slot) then
            local displacedItem = inventory[targetSlot.bag][targetSlot.slot]

            table.insert(actions, {
                fromBag = curBag,
                fromSlot = curSlot,
                toBag = targetSlot.bag,
                toSlot = targetSlot.slot,
            })

            inventory[targetSlot.bag][targetSlot.slot] = desiredItem
            inventory[curBag][curSlot] = displacedItem

            desiredItem.bag = targetSlot.bag
            desiredItem.slot = targetSlot.slot
            if displacedItem then
                displacedItem.bag = curBag
                displacedItem.slot = curSlot
            end
        end
    end

    return actions
end
