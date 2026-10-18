-- Keystone.lua
-- Dedicated Mythic+ keystone auto-slotter and group announcer
-- Automatically slots your keystone into the Font of Power receptacle in 0ms
-- Fast, event-driven, zero polling, zero continuous OnUpdate

local addonName, DQ = ...

DQ.Keystone = {}

-- Safe print helper
local function PrintMsg(msg)
    local formatted = "|cff00e5ff[DistractionQoL]|r " .. tostring(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(formatted)
    elseif print then
        print(formatted)
    end
end

local lastAnnouncedKey = nil
local lastAnnounceTime = 0

function DQ.Keystone:HandleReceptacleOpen()
    local autoSlot = DQ.Config and DQ.Config:Get("mythicPlus", "autoSlot")
    if autoSlot == false then return end

    -- Shift key bypass: hold SHIFT to prevent auto-slotting if manual control is desired
    if IsShiftKeyDown and IsShiftKeyDown() then return end

    if not C_ChallengeMode or not C_ChallengeMode.SlotKeystone then return end

    -- Guard: don't attempt if a keystone is already in the receptacle
    if C_ChallengeMode.HasSlottedKeystone and C_ChallengeMode.HasSlottedKeystone() then
        return
    end

    -- Slot keystone in 0ms upon pedestal interaction
    C_Timer.After(0.05, function()
        if C_ChallengeMode.HasSlottedKeystone and C_ChallengeMode.HasSlottedKeystone() then
            return
        end

        local slotted = false
        if C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemLink and C_Container.PickupContainerItem then
            for bag = 0, 4 do
                local numSlots = C_Container.GetContainerNumSlots(bag) or 0
                for slot = 1, numSlots do
                    local link = C_Container.GetContainerItemLink(bag, slot)
                    if link and link:match("|Hkeystone:") then
                        C_Container.PickupContainerItem(bag, slot)
                        if CursorHasItem and CursorHasItem() then
                            pcall(C_ChallengeMode.SlotKeystone)
                            slotted = true
                            break
                        end
                    end
                end
                if slotted then break end
            end
        end

        if not slotted then
            pcall(C_ChallengeMode.SlotKeystone)
        end
    end)
end

function DQ.Keystone:HandleKeystoneSlotted()
    local announce = DQ.Config and DQ.Config:Get("mythicPlus", "announceSlot")
    if announce == false then return end

    if not C_ChallengeMode or not C_ChallengeMode.GetSlottedKeystoneInfo then return end

    local mapID, affixIDs, level = C_ChallengeMode.GetSlottedKeystoneInfo()
    if not mapID or not level or level <= 0 then return end

    local now = GetTime and GetTime() or 0
    local keyID = string.format("%d:%d", mapID, level)

    -- Debounce: avoid announcing same key multiple times within 10 seconds
    if keyID == lastAnnouncedKey and (now - lastAnnounceTime) < 10 then
        return
    end
    lastAnnouncedKey = keyID
    lastAnnounceTime = now

    local dungeonName = (C_ChallengeMode.GetMapUIInfo and C_ChallengeMode.GetMapUIInfo(mapID)) or "Mazmorra"
    local L = DQ.L or {}
    local fmt = L["MSG_KEYSTONE_SLOTTED"] or "Piedra insertada: %s (+%d)"
    local msg = string.format(fmt, tostring(dungeonName), level)
    local formattedChatMsg = "[DistractionQoL] " .. msg

    -- Announce to Party or Raid chat
    if IsInGroup and IsInGroup() then
        local channel = (IsInRaid and IsInRaid()) and "RAID" or "PARTY"
        if SendChatMessage then
            pcall(SendChatMessage, formattedChatMsg, channel)
        end
    end

    PrintMsg("|cff00ff00" .. msg .. "|r")
end

local function HookChallengesFrame()
    if ChallengesKeystoneFrame and not DQ.Keystone.isFrameHooked then
        DQ.Keystone.isFrameHooked = true
        ChallengesKeystoneFrame:HookScript("OnShow", function()
            DQ.Keystone:HandleReceptacleOpen()
        end)
    end
end

function DQ.Keystone:Init()
    local frame = CreateFrame("Frame")

    -- Note: Blizzard's native event is spelled "RECEPTABLE" with a T instead of "RECEPTACLE"
    pcall(frame.RegisterEvent, frame, "CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN")
    pcall(frame.RegisterEvent, frame, "CHALLENGE_MODE_KEYSTONE_SLOTTED")

    frame:SetScript("OnEvent", function(self, event)
        if event == "CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN" then
            DQ.Keystone:HandleReceptacleOpen()
        elseif event == "CHALLENGE_MODE_KEYSTONE_SLOTTED" then
            DQ.Keystone:HandleKeystoneSlotted()
        end
    end)

    -- Also hook ChallengesKeystoneFrame:OnShow as a secondary rock-solid trigger
    if ChallengesKeystoneFrame then
        HookChallengesFrame()
    else
        local loader = CreateFrame("Frame")
        loader:RegisterEvent("ADDON_LOADED")
        loader:SetScript("OnEvent", function(self, event, loadedAddon)
            if loadedAddon == "Blizzard_ChallengesUI" then
                HookChallengesFrame()
                self:UnregisterEvent("ADDON_LOADED")
            end
        end)
    end

    self.frame = frame
end

