-- ConsumablesLogic.lua
-- Pure business logic for Midnight (12.x) consumables: detection, classification, and mouse wheel rotation
-- Fully decoupled from UI frames, safe for unit testing in offline Lua test runners

local addonName, DQ = ...

DQ.ConsumablesLogic = {}

-- Midnight (12.x) Endgame Consumable Catalog
DQ.ConsumablesLogic.CATALOG = {
    RUNE = {
        { id = 259085, key = "void_touched_rune", en = "Void-Touched Augment Rune", es = "Runa de Aumento Tocada por el Vacío", priority = 100 },
    },
    FLASK = {
        { key = "shattered_sun", en = "Flask of the Shattered Sun", es = "Frasco del Sol Devastado", priority = 100 },
        { key = "blood_knights", en = "Flask of the Blood Knights", es = "Frasco de los Caballeros de Sangre", priority = 90 },
        { key = "magisters",     en = "Flask of the Magisters",     es = "Frasco de los Magister",     priority = 80 },
        { key = "thalassian",    en = "Flask of Thalassian Resistance", es = "Frasco de Resistencia Talassiana", priority = 70 },
        { key = "sindorei",      en = "Sin'dorei Flask",            es = "Frasco Sin'dorei",           priority = 60 },
        { key = "sunwell",       en = "Flask of the Sunwell",       es = "Frasco de la Fuente del Sol", priority = 50 },
    },
    FOOD = {
        { key = "silvermoon_parade", en = "Silvermoon Parade", es = "Desfile de Lunargenta", priority = 100 },
        { key = "blooming_feast",   en = "Blooming Feast",   es = "Festín Floreciente", priority = 95 },
        { key = "hearty_feast",     en = "Hearty Feast",     es = "Festín Copioso",     priority = 90 },
        { key = "hearty_food",      en = "Hearty",           es = "Copios",             priority = 80 },
        { key = "spiced_biscuits",  en = "Spiced Biscuits",  es = "Galletas Especiadas", priority = 70 },
        { key = "felberry_figs",    en = "Felberry Figs",    es = "Higos de Vilabaya",   priority = 65 },
        { key = "sunstrider",       en = "Sunstrider",       es = "Caminante del Sol",   priority = 60 },
    },
    WEAPON = {
        { key = "phoenix_oil",     en = "Thalassian Phoenix Oil",    es = "Aceite de Fénix Talassiano", priority = 100 },
        { key = "smuggler_edge",   en = "Smuggler's Enchanted Edge", es = "Filo Encantado de Contrabandista", priority = 90 },
        { key = "oil_of_dawn",     en = "Oil of Dawn",               es = "Aceite del Amanecer", priority = 80 },
        { key = "refulgent_whet",  en = "Refulgent Whetstone",       es = "Piedra de Afilar Refulgente", priority = 70 },
        { key = "refulgent_weight", en = "Refulgent Weightstone",    es = "Piedra de Contrapeso Refulgente", priority = 65 },
    }
}

-- Checks if a given item name or itemID matches a strictly Midnight consumable category
function DQ.ConsumablesLogic.ClassifyItem(itemName, itemID)
    if not itemName and not itemID then return nil, 0 end
    local lowerName = itemName and itemName:lower() or ""

    -- 1. Check Rune (Strictly Void-Touched Augment Rune in Midnight)
    if itemID == 259085 or lowerName:find("void%-touched") or lowerName:find("tocada por el vac[íi]o") then
        return "RUNE", 100
    end

    -- 2. Check Flasks (Strictly Midnight Endgame Flasks)
    if lowerName:find("shattered sun") or lowerName:find("sol devastado") then
        return "FLASK", 100
    elseif lowerName:find("blood knight") or (lowerName:find("caballero") and lowerName:find("sangre")) then
        return "FLASK", 90
    elseif lowerName:find("magister") then
        return "FLASK", 80
    elseif lowerName:find("thalassian resistance") or lowerName:find("resistencia talassiana") then
        return "FLASK", 70
    elseif lowerName:find("sin'dorei") or lowerName:find("sindorei") or lowerName:find("sunwell") or lowerName:find("fuente del sol") then
        return "FLASK", 60
    end

    -- 3. Check Food (Strictly Midnight Cooking & Feasts)
    if lowerName:find("silvermoon parade") or lowerName:find("desfile de lunargenta") then
        return "FOOD", 100
    elseif lowerName:find("blooming feast") or lowerName:find("fest[íi]n floreciente") then
        return "FOOD", 95
    elseif lowerName:find("hearty feast") or lowerName:find("fest[íi]n copioso") then
        return "FOOD", 90
    elseif lowerName:find("hearty") or lowerName:find("copios") then
        return "FOOD", 80
    elseif lowerName:find("felberry") or lowerName:find("vilabaya") or lowerName:find("spiced biscuit") or lowerName:find("galleta especiada") then
        return "FOOD", 70
    elseif lowerName:find("sunstrider") or lowerName:find("caminante del sol") then
        return "FOOD", 65
    end

    -- 4. Check Weapon Enchants/Oils (Strictly Midnight Enchanting & Blacksmithing)
    if lowerName:find("phoenix oil") or lowerName:find("f[ée]nix talassian") then
        return "WEAPON", 100
    elseif lowerName:find("smuggler") or lowerName:find("contrabandista") then
        return "WEAPON", 90
    elseif lowerName:find("oil of dawn") or lowerName:find("aceite del amanecer") then
        return "WEAPON", 80
    elseif lowerName:find("refulgent whetstone") or lowerName:find("afilar refulgente") then
        return "WEAPON", 70
    elseif lowerName:find("refulgent weightstone") or lowerName:find("contrapeso refulgente") then
        return "WEAPON", 65
    end

    return nil, 0
end

-- Cycles an index based on mouse wheel delta (positive = scroll up, negative = scroll down)
-- Handles wrapping cleanly around [1, totalCount]
function DQ.ConsumablesLogic.CycleIndex(currentIndex, totalCount, delta)
    if not totalCount or totalCount <= 1 then return 1 end
    currentIndex = currentIndex or 1

    if delta > 0 then
        -- Scroll Up -> Next
        currentIndex = currentIndex + 1
        if currentIndex > totalCount then
            currentIndex = 1
        end
    elseif delta < 0 then
        -- Scroll Down -> Previous
        currentIndex = currentIndex - 1
        if currentIndex < 1 then
            currentIndex = totalCount
        end
    end

    return currentIndex
end

-- Groups and sorts a flat list of bag items into consumable categories
-- Returns a dictionary: { RUNE = { items... }, FLASK = { items... }, ... }
function DQ.ConsumablesLogic.GroupBagItems(flatItems)
    local grouped = {
        FLASK  = {},
        FOOD   = {},
        RUNE   = {},
        WEAPON = {},
    }

    if not flatItems then return grouped end

    local byCategoryItem = {
        FLASK  = {},
        FOOD   = {},
        RUNE   = {},
        WEAPON = {},
    }

    for _, item in ipairs(flatItems) do
        local category, priority = DQ.ConsumablesLogic.ClassifyItem(item.name, item.itemID)
        if category and byCategoryItem[category] then
            local existing = byCategoryItem[category][item.itemID]
            if existing then
                existing.count = existing.count + (item.count or 1)
            else
                local entry = {
                    itemID     = item.itemID,
                    name       = item.name or ("Item " .. tostring(item.itemID)),
                    icon       = item.icon or 134400,
                    count      = item.count or 1,
                    bag        = item.bag,
                    slot       = item.slot,
                    itemLink   = item.itemLink,
                    priority   = priority,
                }
                byCategoryItem[category][item.itemID] = entry
                table.insert(grouped[category], entry)
            end
        end
    end

    -- Sort each category by priority descending, then count descending
    for cat, list in pairs(grouped) do
        table.sort(list, function(a, b)
            if a.priority ~= b.priority then
                return a.priority > b.priority
            end
            return a.count > b.count
        end)
    end

    return grouped
end

-- Returns fallback display icon for empty category
function DQ.ConsumablesLogic.GetCategoryFallbackIcon(category)
    if category == "FLASK" then
        return "Interface\\Icons\\inv_potion_105"
    elseif category == "FOOD" then
        return "Interface\\Icons\\spell_misc_food"
    elseif category == "RUNE" then
        return "Interface\\Icons\\inv_misc_rune_01"
    elseif category == "WEAPON" then
        return "Interface\\Icons\\inv_stone_sharpening_01"
    end
    return "Interface\\Icons\\inv_misc_questionmark"
end

-- Builds safe macro string for SecureActionButtonTemplate
-- If WEAPON, left click enchants MH (slot 16), right click enchants OH (slot 17)
function DQ.ConsumablesLogic.BuildMacroText(category, itemID)
    if not itemID then return "" end
    if category == "WEAPON" then
        return "/use item:" .. tostring(itemID) .. "\n/use [btn:2] 17; 16"
    end
    return "/use item:" .. tostring(itemID)
end

-- Scans player bags 0 to 4 in retail WoW
function DQ.ConsumablesLogic.ScanPlayerBags()
    local flatItems = {}
    if not C_Container or not C_Container.GetContainerNumSlots then return flatItems end

    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID then
                local itemName = itemInfo.itemName
                if not itemName and C_Item and C_Item.GetItemInfo then
                    itemName = C_Item.GetItemInfo(itemInfo.itemID)
                end
                if not itemName and itemInfo.hyperlink then
                    itemName = itemInfo.hyperlink:match("%[(.-)%]")
                end
                if not itemName or itemName == "" then
                    itemName = "Item " .. tostring(itemInfo.itemID)
                end

                local iconTex = itemInfo.iconFileID
                if (not iconTex or iconTex == 0) and C_Item and C_Item.GetItemIconByID then
                    iconTex = C_Item.GetItemIconByID(itemInfo.itemID)
                end
                if (not iconTex or iconTex == 0) and C_Item and C_Item.GetItemInfoInstant then
                    local _, _, _, _, instantIcon = C_Item.GetItemInfoInstant(itemInfo.itemID)
                    if instantIcon and instantIcon ~= 0 then
                        iconTex = instantIcon
                    end
                end

                table.insert(flatItems, {
                    itemID   = itemInfo.itemID,
                    name     = itemName,
                    icon     = (iconTex and iconTex ~= 0) and iconTex or "Interface\\Icons\\inv_misc_questionmark",
                    count    = itemInfo.stackCount or 1,
                    bag      = bag,
                    slot     = slot,
                    itemLink = itemInfo.hyperlink,
                })
            end
        end
    end

    return flatItems
end
