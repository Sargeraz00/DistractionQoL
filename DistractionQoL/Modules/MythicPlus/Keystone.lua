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

    if not C_ChallengeMode or not C_ChallengeMode.SlotKeystone then return end

    -- Guard: don't attempt if a keystone is already in the receptacle
    if C_ChallengeMode.HasSlottedKeystone and C_ChallengeMode.HasSlottedKeystone() then
        return
    end

    -- Slot keystone in 0ms upon pedestal interaction
    C_Timer.After(0.05, function()
        if C_ChallengeMode.HasSlottedKeystone and not C_ChallengeMode.HasSlottedKeystone() then
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

function DQ.Keystone:Init()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHALLENGE_MODE_KEYSTONE_RECEPTACLE_OPEN")
    frame:RegisterEvent("CHALLENGE_MODE_KEYSTONE_SLOTTED")

    frame:SetScript("OnEvent", function(self, event)
        if event == "CHALLENGE_MODE_KEYSTONE_RECEPTACLE_OPEN" then
            DQ.Keystone:HandleReceptacleOpen()
        elseif event == "CHALLENGE_MODE_KEYSTONE_SLOTTED" then
            DQ.Keystone:HandleKeystoneSlotted()
        end
    end)

    self.frame = frame
end
