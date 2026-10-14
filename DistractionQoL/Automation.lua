-- Automation.lua
-- Quality-of-Life automations module for DistractionQoL
-- Fast, event-driven, zero polling, zero continuous OnUpdate

local addonName, DQ = ...

DQ.Automation = {}

-- Safe print helper
local function PrintMsg(msg)
    local formatted = "|cff00e5ff[DistractionQoL]|r " .. tostring(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(formatted)
    elseif print then
        print(formatted)
    end
end

-- Formats copper into gold/silver/copper string
local function FormatMoney(copper)
    if GetCoinTextureString then
        return GetCoinTextureString(copper)
    end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    return string.format("%dg %ds %dc", g, s, c)
end

-- Helper to safely retrieve item sell price across WoW 12.1.5 (post-Deprecated_ItemScript removal)
local function GetItemSellPrice(hyperlink, itemID)
    if not hyperlink and not itemID then return 0 end

    -- 1. Modern C_Item API (Retail & Midnight 12.1.5+)
    if C_Item and C_Item.GetItemInfo then
        local _, _, _, _, _, _, _, _, _, _, price = C_Item.GetItemInfo(hyperlink or itemID)
        if price and price > 0 then return price end
    end

    -- 2. Modern Instant info fallback (does not depend on server query caching)
    if C_Item and C_Item.GetItemInfoInstant then
        local instant = C_Item.GetItemInfoInstant(itemID or hyperlink)
        if instant and instant.sellPrice and instant.sellPrice > 0 then
            return instant.sellPrice
        end
    end

    -- 3. Legacy global GetItemInfo fallback (if available)
    if GetItemInfo then
        local _, _, _, _, _, _, _, _, _, _, price = GetItemInfo(hyperlink or itemID)
        if price and price > 0 then return price end
    end

    return 0
end

-- Sells all poor (grey) quality items in bags
local function SellJunkItems()
    if not C_Container or not C_Container.GetContainerNumSlots then return end
    local L = DQ.L or {}
    local soldCount = 0
    local totalGain = 0

    for bag = 0, 5 do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.quality == 0 and not info.hasNoValue and info.hyperlink then
                local itemSellPrice = GetItemSellPrice(info.hyperlink, info.itemID)
                local stack = info.stackCount or 1
                local itemPrice = (itemSellPrice or 0) * stack
                totalGain = totalGain + itemPrice
                soldCount = soldCount + 1
                C_Container.UseContainerItem(bag, slot)
            end
        end
    end

    if soldCount > 0 and totalGain > 0 then
        local fmt = L["MSG_JUNK_SOLD"] or "Basura gris vendida por: %s (%d objetos)"
        PrintMsg(string.format(fmt, FormatMoney(totalGain), soldCount))
    end
end

-- Auto-repairs gear at vendors
local function HandleAutoRepair()
    if not CanMerchantRepair or not CanMerchantRepair() then return end
    local cost, canRepair = GetRepairAllCost()
    if not canRepair or cost <= 0 then return end

    local L = DQ.L or {}
    local guildRepairSetting = DQ.Config:Get("automation", "guildRepair")
    local canGuild = false

    if guildRepairSetting and CanGuildBankRepair and CanGuildBankRepair() then
        local withdraw = GetGuildBankWithdrawMoney and GetGuildBankWithdrawMoney() or 0
        if withdraw == -1 or withdraw >= cost then
            canGuild = true
        end
    end

    if canGuild then
        RepairAllItems(true)
        local fmt = L["MSG_GUILD_REPAIRED"] or "Equipo reparado con fondos de hermandad por: %s"
        PrintMsg(string.format(fmt, FormatMoney(cost)))
    else
        local playerMoney = GetMoney and GetMoney() or 0
        if playerMoney >= cost then
            RepairAllItems(false)
            local fmt = L["MSG_REPAIRED"] or "Equipo reparado por: %s"
            PrintMsg(string.format(fmt, FormatMoney(cost)))
        end
    end
end

-- Fast Loot: empties container in 1 tick
local function HandleFastLoot()
    if not GetNumLootItems or not LootSlot then return end
    local num = GetNumLootItems()
    if num and num > 0 then
        for i = num, 1, -1 do
            LootSlot(i)
        end
    end
end

-- Initializes automation event handlers
function DQ.Automation:Init()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("RESURRECT_REQUEST")
    frame:RegisterEvent("MERCHANT_SHOW")
    frame:RegisterEvent("CINEMATIC_START")
    frame:RegisterEvent("PLAY_MOVIE")
    frame:RegisterEvent("DUEL_REQUESTED")
    frame:RegisterEvent("PET_BATTLE_PVP_DUEL_REQUESTED")
    frame:RegisterEvent("LOOT_READY")

    frame:SetScript("OnEvent", function(self, event, arg1)
        local L = DQ.L or {}

        -- 1. AUTO RESURRECTION
        if event == "RESURRECT_REQUEST" then
            if DQ.Config:Get("automation", "autoRes", "enabled") then
                local inviter = arg1 or "Alguien"
                local inCombat = DQ.Detection and DQ.Detection.IsCombatActive and DQ.Detection:IsCombatActive()
                local allowCombat = DQ.Config:Get("automation", "autoRes", "inCombat")

                if inCombat and not allowCombat then
                    local fmt = L["MSG_AUTO_RES_BLOCKED_COMBAT"] or "Resurrección de %s recibida, pero omitida por estar en combate (Battle Rez)."
                    PrintMsg(string.format(fmt, tostring(inviter)))
                    return
                end

                -- 200ms delay to allow game engine dialog to settle safely
                C_Timer.After(0.2, function()
                    local ok, err = pcall(AcceptResurrect)
                    if ok then
                        if StaticPopup_Hide then
                            StaticPopup_Hide("RESURRECT")
                            StaticPopup_Hide("RESURRECT_NO_SICKNESS")
                            StaticPopup_Hide("RESURRECT_NO_TIMER")
                        end
                        local fmt = L["MSG_AUTO_RES_ACCEPTED"] or "Resurrección de %s aceptada automáticamente."
                        PrintMsg(string.format(fmt, tostring(inviter)))
                    end
                end)
            end

        -- 2. AUTO SELL JUNK & AUTO REPAIR
        elseif event == "MERCHANT_SHOW" then
            if DQ.Config:Get("automation", "autoSellJunk") then
                SellJunkItems()
            end
            if DQ.Config:Get("automation", "autoRepair") then
                HandleAutoRepair()
            end

        -- 3. AUTO SKIP CINEMATICS & MOVIES
        elseif event == "CINEMATIC_START" then
            if DQ.Config:Get("automation", "autoSkipCinematics") then
                -- Guard against InCombatLockdown to avoid ADDON_ACTION_BLOCKED in 12.1.5
                if not (InCombatLockdown and InCombatLockdown()) then
                    if CinematicFrame_CancelCinematic then
                        pcall(CinematicFrame_CancelCinematic)
                    elseif StopCinematic then
                        pcall(StopCinematic)
                    end
                end
            end
        elseif event == "PLAY_MOVIE" then
            if DQ.Config:Get("automation", "autoSkipCinematics") then
                -- Guard against InCombatLockdown to avoid ADDON_ACTION_BLOCKED in 12.1.5
                if not (InCombatLockdown and InCombatLockdown()) then
                    if GameMovieFinished then
                        pcall(GameMovieFinished)
                    elseif MovieFrame_StopMovie then
                        pcall(MovieFrame_StopMovie)
                    end
                end
            end

        -- 4. BLOCK DUELS IN INSTANCES
        elseif event == "DUEL_REQUESTED" or event == "PET_BATTLE_PVP_DUEL_REQUESTED" then
            if DQ.Config:Get("automation", "blockDuels") and IsInInstance() then
                if CancelDuel then CancelDuel() end
                if C_PetBattles and C_PetBattles.CancelPVPMatchmaking then
                    C_PetBattles.CancelPVPMatchmaking()
                end
                if StaticPopup_Hide then
                    StaticPopup_Hide("DUEL_REQUESTED")
                    StaticPopup_Hide("PET_BATTLE_PVP_DUEL_REQUESTED")
                end
                PrintMsg(L["MSG_DUEL_BLOCKED"] or "Duelo bloqueado automáticamente por estar en instancia.")
            end

        -- 5. FAST LOOT
        elseif event == "LOOT_READY" then
            if DQ.Config:Get("automation", "fastLoot") then
                HandleFastLoot()
            end
        end
    end)

    self.frame = frame
end
