-- WipeRelease.lua
-- Dedicated Mythic+ Full Wipe auto-release module
-- Detects when the entire party has died in a Mythic+ key and combat has ended
-- Automatically releases spirit (or unlocks instant release) to save key timer

local addonName, DQ = ...

DQ.WipeRelease = {}
DQ.WipeRelease.isFullWipeActive = false

-- Safe print helper
local function PrintMsg(msg)
    local formatted = "|cff00e5ff[DistractionQoL]|r " .. tostring(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(formatted)
    elseif print then
        print(formatted)
    end
end

-- Checks if player is inside an active Mythic+ dungeon run
local function IsInMythicPlus()
    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive then
        return C_ChallengeMode.IsChallengeModeActive()
    end
    return false
end

-- Checks if all group members are currently dead or ghosts
local function IsPartyFullWipe()
    if not UnitIsDeadOrGhost("player") then return false end

    local numGroup = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
    if numGroup == 0 then return false end

    for i = 1, numGroup do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
            return false
        end
    end

    return true
end

function DQ.WipeRelease:CheckWipeStatus()
    if not IsInMythicPlus() then return end

    local enabled = DQ.Config and DQ.Config:Get("mythicPlus", "autoReleaseOnWipe")
    if enabled == false then return end

    -- Allow 0.6s for combat status and death flags to settle
    C_Timer.After(0.6, function()
        if not IsInMythicPlus() then return end

        if IsPartyFullWipe() then
            -- Double check after combat drops
            if not InCombatLockdown or not InCombatLockdown() then
                DQ.WipeRelease.isFullWipeActive = true

                local L = DQ.L or {}
                PrintMsg(L["MSG_FULL_WIPE_RELEASED"] or "¡Wipe total detectado! Liberando espíritu automáticamente para salvar tiempo de la llave.")

                -- Close static popup dialog if open
                if StaticPopup_Hide then
                    StaticPopup_Hide("DEATH")
                    StaticPopup_Hide("DEATH_RELEASE")
                end

                -- Release spirit automatically
                if RepopMe then
                    pcall(RepopMe)
                end
            else
                -- Combat still active, retry in 0.5s
                C_Timer.After(0.5, function()
                    if IsPartyFullWipe() and (not InCombatLockdown or not InCombatLockdown()) then
                        DQ.WipeRelease.isFullWipeActive = true
                        if RepopMe then pcall(RepopMe) end
                    end
                end)
            end
        end
    end)
end

function DQ.WipeRelease:Init()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_DEAD")
    frame:RegisterEvent("PLAYER_ALIVE")
    frame:RegisterEvent("PLAYER_UNGHOST")
    frame:RegisterEvent("UNIT_DIED")
    frame:RegisterEvent("ENCOUNTER_END")

    frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_DEAD" or event == "ENCOUNTER_END" then
            DQ.WipeRelease:CheckWipeStatus()
        elseif event == "UNIT_DIED" then
            -- Full wipe evaluation is only relevant if the player is currently dead or ghost
            if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
                local isRelevant = false
                if issecretvalue and issecretvalue(arg1) then
                    -- In Midnight 12.x, arg1 is a secret string in instances.
                    -- Since player is already dead, evaluate wipe status safely without indexing secret values.
                    isRelevant = true
                elseif type(arg1) == "string" then
                    isRelevant = (string.find(arg1, "party") ~= nil) or (arg1 == "player")
                else
                    isRelevant = true
                end

                if isRelevant then
                    DQ.WipeRelease:CheckWipeStatus()
                end
            end
        elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
            DQ.WipeRelease.isFullWipeActive = false
        end
    end)

    self.frame = frame
end
