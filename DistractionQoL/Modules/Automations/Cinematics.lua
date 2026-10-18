-- Cinematics.lua
-- Dedicated module for auto-skipping cinematics/movies and blocking instance duels
-- Guarded against InCombatLockdown to avoid ADDON_ACTION_BLOCKED in WoW 12.1.5

local addonName, DQ = ...

DQ.Cinematics = {}

local function PrintMsg(msg)
    local formatted = "|cff00e5ff[DistractionQoL]|r " .. tostring(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(formatted)
    elseif print then
        print(formatted)
    end
end

local function DoSkipCinematic()
    if InCombatLockdown and InCombatLockdown() then return end
    if CinematicFrame_CancelCinematic then
        pcall(CinematicFrame_CancelCinematic)
    elseif StopCinematic then
        pcall(StopCinematic)
    end
end

local function DoSkipMovie()
    if InCombatLockdown and InCombatLockdown() then return end
    if GameMovieFinished then
        pcall(GameMovieFinished)
    elseif MovieFrame_StopMovie then
        pcall(MovieFrame_StopMovie)
    end
end

DQ.Cinematics.SkipCinematic = DoSkipCinematic
DQ.Cinematics.SkipMovie = DoSkipMovie

function DQ.Cinematics:Init()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CINEMATIC_START")
    frame:RegisterEvent("PLAY_MOVIE")
    frame:RegisterEvent("DUEL_REQUESTED")
    frame:RegisterEvent("PET_BATTLE_PVP_DUEL_REQUESTED")

    frame:SetScript("OnEvent", function(self, event)
        local L = DQ.L or {}

        if event == "CINEMATIC_START" then
            if DQ.Config:Get("automation", "autoSkipCinematics") then
                if DQ.ConflictResolver and DQ.ConflictResolver.CheckAndExecute then
                    DQ.ConflictResolver:CheckAndExecute("autoSkipCinematics", DoSkipCinematic)
                else
                    DoSkipCinematic()
                end
            end

        elseif event == "PLAY_MOVIE" then
            if DQ.Config:Get("automation", "autoSkipCinematics") then
                if DQ.ConflictResolver and DQ.ConflictResolver.CheckAndExecute then
                    DQ.ConflictResolver:CheckAndExecute("autoSkipCinematics", DoSkipMovie)
                else
                    DoSkipMovie()
                end
            end

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
        end
    end)

    self.frame = frame
end
