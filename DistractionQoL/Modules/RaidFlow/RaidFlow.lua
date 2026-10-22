-- RaidFlow.lua
-- Raid Flow, Readiness, and Anti-Distraction module for DistractionQoL
-- Pure event-driven, zero polling, zero continuous OnUpdate

local addonName, DQ = ...

DQ.RaidFlow = {}

-- Safe print helper
local function PrintMsg(msg)
    local formatted = "|cff00e5ff[DistractionQoL]|r " .. tostring(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(formatted)
    elseif print then
        print(formatted)
    end
end

-- Checks and notifies missing consumables
function DQ.RaidFlow:CheckConsumables(isManual)
    if not DQ.Detection or not DQ.Detection.CheckPlayerConsumables then return end
    local missing, missingKeys = DQ.Detection:CheckPlayerConsumables()
    local L = DQ.L or {}

    local hasMissing = (missing and #missing > 0)
    if hasMissing then
        local missingStr = table.concat(missing, ", ")
        local fmt = L["MSG_MISSING_CONSUMABLES"] or "|cffff3333[¡Aviso de Consumibles!]|r Te falta: %s"
        local alertText = string.format(fmt, "|cffffcc00" .. missingStr .. "|r")
        PrintMsg(alertText)

        -- Flash on-screen raid notice banner
        if RaidNotice_AddMessage and RaidWarningFrame then
            pcall(RaidNotice_AddMessage, RaidWarningFrame, alertText, ChatTypeInfo["RAID_WARNING"] or { r = 1, g = 0.3, b = 0.3 })
        end

        -- Play a short alert click/warning sound
        if PlaySound then
            pcall(PlaySound, SOUNDKIT.RAID_WARNING or 8959, "Master")
        end
    else
        PrintMsg(L["ALL_BUFFS_OK"] or "|cff00ff00¡Todos los consumibles activos! Listo para el pull.|r")
    end

    -- Trigger interactive clickable Consumables Bar
    if DQ.ConsumablesBar then
        if isManual then
            DQ.ConsumablesBar:OpenManager()
        elseif (hasMissing or (missingKeys and next(missingKeys))) and DQ.ConsumablesBar.ShowBar then
            DQ.ConsumablesBar:ShowBar(missingKeys, false)
        end
    end
end

local lastExpWarnTime = 0

-- Initializes event handlers for raid readiness
function DQ.RaidFlow:Init()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("READY_CHECK")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("LFG_PROPOSAL_SHOW")

    -- Register DBM / BigWigs addon communication prefixes for pull timers
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        pcall(C_ChatInfo.RegisterAddonMessagePrefix, "D4")
        pcall(C_ChatInfo.RegisterAddonMessagePrefix, "BigWigs")
    end

    frame:SetScript("OnEvent", function(self, event, prefix, msg)
        local L = DQ.L or {}

        -- 1. READY CHECK EVENT
        if event == "READY_CHECK" then
            -- Flash Windows Taskbar
            if DQ.Config:Get("raidFlow", "flashTaskbar") and FlashClientIcon then
                FlashClientIcon()
            end

            -- Audio ping on Master channel
            if DQ.Config:Get("raidFlow", "readyCheckSound") and PlaySound then
                pcall(PlaySound, SOUNDKIT.READY_CHECK or 8959, "Master")
            end

            -- Missing Consumables Check
            if DQ.Config:Get("raidFlow", "checkConsumables") then
                DQ.RaidFlow:CheckConsumables(false)
            end

        -- 2. DBM / BIGWIGS PULL TIMER DETECTOR
        elseif event == "CHAT_MSG_ADDON" then
            if not DQ.Config:Get("raidFlow", "flashTaskbar") then return end

            if prefix == "D4" and msg and msg:find("PT") then
                -- DBM pull timer format: PT\t<seconds>
                if FlashClientIcon then FlashClientIcon() end
            elseif prefix == "BigWigs" and msg and (msg:find("Pull") or msg:find("pull")) then
                -- BigWigs pull timer broadcast
                if FlashClientIcon then FlashClientIcon() end
            end

        -- 3. EXPIRING CONSUMABLES WARNING (OUT OF COMBAT IN INSTANCES)
        elseif event == "PLAYER_REGEN_ENABLED" then
            if IsInInstance and IsInInstance() then
                local now = GetTime and GetTime() or 0
                if (now - lastExpWarnTime) >= 60 then
                    if DQ.Detection and DQ.Detection.CheckExpiringConsumables then
                        local expiring = DQ.Detection:CheckExpiringConsumables(300) -- 5 min
                        if #expiring > 0 then
                            lastExpWarnTime = now
                            for _, item in ipairs(expiring) do
                                local fmt = L["MSG_CONSUMABLE_EXPIRING"] or "Aviso de Consumibles: Tu |cffffcc00%s|r expira en |cffff3333%d min|r. Renuévala antes del próximo pull."
                                PrintMsg(string.format(fmt, tostring(item.name), item.minutes))
                            end
                        end
                    end
                end
            end

        -- 4. LFG / DUNGEON QUEUE PROPOSAL ALERT
        elseif event == "LFG_PROPOSAL_SHOW" then
            if DQ.Config:Get("raidFlow", "lfgAlert") ~= false then
                if FlashClientIcon then FlashClientIcon() end
                if PlaySound then
                    pcall(PlaySound, SOUNDKIT.READY_CHECK or 8959, "Master")
                end
                local fmt = L["MSG_LFG_PROPOSAL"] or "¡Llamada de Buscador! Tu grupo de mazmorra o banda está listo."
                PrintMsg("|cff00ff00" .. fmt .. "|r")
            end

        -- 5. RAID ENTRY CONFLICT CHECK
        elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            if C_Timer and C_Timer.After then
                C_Timer.After(2, function()
                    DQ.RaidFlow:CheckRaidConsumablesConflict(false)
                end)
            else
                DQ.RaidFlow:CheckRaidConsumablesConflict(false)
            end
        end
    end)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    self.frame = frame
end

local hasPromptedConsumablesRaid = false

-- Checks for consumables conflict with EllesmereUI upon entering raid, dungeon, or group
function DQ.RaidFlow:CheckRaidConsumablesConflict(forcePrompt)
    if not DQ.ConflictResolver then return end

    local inInstance, instanceType = IsInInstance and IsInInstance()
    local isRaidOrGroup = (inInstance and (instanceType == "raid" or instanceType == "party"))
                       or (IsInRaid and IsInRaid())
                       or (IsInGroup and IsInGroup())
                       or forcePrompt

    if not isRaidOrGroup then return end

    local ext = DQ.ConflictResolver:DetectConflict("consumables") or (forcePrompt and "EllesmereUI")
    if not ext then return end

    local dontAsk = DQ.ConflictResolver:GetDontAskAgain("consumables")
    local choice = DQ.ConflictResolver:GetChoice("consumables")

    if not dontAsk or not choice or forcePrompt then
        if not hasPromptedConsumablesRaid or forcePrompt then
            hasPromptedConsumablesRaid = true
            DQ.ConflictResolver:QueuePrompt("consumables", ext, function(selectedChoice, remember)
                DQ.ConflictResolver:SetChoice("consumables", selectedChoice, remember)
            end)
        end
    else
        DQ.ConflictResolver:ApplyHandover("consumables", choice, ext)
    end
end
