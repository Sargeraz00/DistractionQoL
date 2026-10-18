-- FastLoot.lua
-- Dedicated instant zero-delay fast loot module
-- Empties loot container in 1 tick without continuous OnUpdate

local addonName, DQ = ...

DQ.FastLoot = {}

local function HandleFastLoot()
    if not GetNumLootItems or not LootSlot then return end
    local num = GetNumLootItems()
    if num and num > 0 then
        for i = num, 1, -1 do
            LootSlot(i)
        end
    end
end

DQ.FastLoot.HandleFastLoot = HandleFastLoot

function DQ.FastLoot:Init()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("LOOT_READY")

    frame:SetScript("OnEvent", function(self, event)
        if event == "LOOT_READY" then
            if DQ.Config:Get("automation", "fastLoot") then
                if DQ.ConflictResolver and DQ.ConflictResolver.CheckAndExecute then
                    DQ.ConflictResolver:CheckAndExecute("fastLoot", function()
                        HandleFastLoot()
                    end)
                else
                    HandleFastLoot()
                end
            end
        end
    end)

    self.frame = frame
end
