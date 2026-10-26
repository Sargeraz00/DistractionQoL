-- CommandHub.lua
-- M+ Dungeon Command Hub & Party Keystone Matrix for DistractionQoL
-- Displays active seasonal M+ dungeons with personal best records, 1-click Hero's Path teleports,
-- and tracks party keystones with addon messaging and 1-click group announcement.
-- Updated and verified for WoW Midnight (12.x).

local addonName, DQ = ...

DQ.CommandHub = {}

local hubFrame = nil
local partyKeys = {}

-- Verified Midnight Season M+ Dungeons & Hero's Path Teleport Spell IDs
local SEASON_PORTALS = {
    { spellID = 1286801, short = "BV",  dungeonID = 3102, defaultName = "The Blinding Vale", names = { "the blinding vale", "blinding vale" } },
    { spellID = 1286804, short = "VA",  dungeonID = 3106, defaultName = "Voidscar Arena", names = { "voidscar arena" } },
    { spellID = 1286807, short = "DoN", dungeonID = 3051, defaultName = "Den of Nalorakk", names = { "den of nalorakk", "den of nalorak" } },
    { spellID = 1286809, short = "MR",  dungeonID = 3090, defaultName = "Murder Row", names = { "murder row" } },
    { spellID = 1286812, short = "AoF", dungeonID = 3191, defaultName = "Altar of Fangs", names = { "altar of fangs" } },
    { spellID = 393256,  short = "RLP", dungeonID = 2361, defaultName = "Ruby Life Pools", names = { "ruby life pools" } },
    { spellID = 1286828, short = "ToS", dungeonID = 1694, defaultName = "Temple of Sethraliss", names = { "temple of sethraliss" } },
    { spellID = 1286831, short = "KR",  dungeonID = 1785, defaultName = "Kings' Rest", names = { "kings' rest", "king's rest" } },
}

-- Lookups
local MAP_TO_SPELL = {}
local SPELL_BY_NAME = {}

local function RebuildTeleportLookups()
    for _, e in ipairs(SEASON_PORTALS) do
        for _, n in ipairs(e.names) do
            SPELL_BY_NAME[n] = e.spellID
        end
        if e.dungeonID and GetLFGDungeonInfo then
            local ok, localName = pcall(GetLFGDungeonInfo, e.dungeonID)
            if ok and type(localName) == "string" and localName ~= "" then
                SPELL_BY_NAME[localName:lower()] = e.spellID
            end
        end
    end

    if C_ChallengeMode and C_ChallengeMode.GetMapTable then
        local maps = C_ChallengeMode.GetMapTable()
        if maps then
            for _, mapID in ipairs(maps) do
                local name = C_ChallengeMode.GetMapUIInfo(mapID)
                if name then
                    local spellID = SPELL_BY_NAME[name:lower()]
                    if spellID then
                        MAP_TO_SPELL[mapID] = spellID
                    end
                end
            end
        end
    end
end

-- Checks if the player has unlocked/learned a teleport spell
local function IsTeleportLearned(spellID)
    if not spellID then return false end
    if IsSpellKnownOrOverridesKnown then
        return IsSpellKnownOrOverridesKnown(spellID)
    elseif C_Spell and C_Spell.IsSpellKnown then
        return C_Spell.IsSpellKnown(spellID)
    end
    return false
end

-- Retrieves player's own keystone
local function GetPlayerKeystone()
    if not C_MythicPlus then return 0, 0 end
    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID and C_MythicPlus.GetOwnedKeystoneChallengeMapID() or 0
    local level = C_MythicPlus.GetOwnedKeystoneLevel and C_MythicPlus.GetOwnedKeystoneLevel() or 0
    return mapID, level
end

-- Broadcasts own keystone to party
local function BroadcastOwnKey()
    if not IsInGroup() then return end
    local mapID, level = GetPlayerKeystone()
    if not mapID or mapID <= 0 or not level or level <= 0 then return end

    local payload = string.format("MYKEY:%d:%d", mapID, level)
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage("DQ_KEYS", payload, IsInRaid() and "RAID" or "PARTY")
    end
end

-- Requests keystones from all party members
local function RequestPartyKeys()
    if not IsInGroup() then return end
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage("DQ_KEYS", "REQ_KEYS", IsInRaid() and "RAID" or "PARTY")
    end
end

-- Creates the modern Obsidian Flat Command Hub Frame
local function CreateCommandHubFrame()
    if hubFrame then return hubFrame end

    local L = DQ.L or {}

    local f = DQ.UI:CreateWindow("DistractionQoLCommandHubFrame", "|cff00e5ffDistractionQoL|r — " .. (L["HUB_TITLE"] or "Centro de Mazmorras M+ (Midnight)"), 520, 520)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    f:SetFrameStrata("HIGH")

    -- ==========================================================
    -- SECTION 1: SEASONAL DUNGEONS & TELEPORTS (Top Half)
    -- ==========================================================
    local secPortals = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    secPortals:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -34)
    secPortals:SetText("|cffffcc00" .. (L["HUB_SEC_PORTALS"] or "Mazmorras de Temporada & Teletransportes") .. "|r")

    local dungeonGrid = CreateFrame("Frame", nil, f)
    dungeonGrid:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -52)
    dungeonGrid:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -52)
    dungeonGrid:SetHeight(220)
    f.dungeonGrid = dungeonGrid

    f.dungeonRows = {}

    -- Build 8 dungeon rows (2 columns of 4)
    local colW = 245
    local rowH = 46
    for i = 1, 8 do
        local col = ((i - 1) % 2)
        local row = math.floor((i - 1) / 2)

        local rowFrame = CreateFrame("Frame", nil, dungeonGrid, "BackdropTemplate")
        rowFrame:SetSize(colW, rowH)
        rowFrame:SetPoint("TOPLEFT", dungeonGrid, "TOPLEFT", col * (colW + 10), -row * (rowH + 6))
        if DQ.Theme and DQ.Theme.ApplyCardStyle then
            DQ.Theme.ApplyCardStyle(rowFrame)
        else
            rowFrame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 },
            })
            rowFrame:SetBackdropColor(0.10, 0.10, 0.14, 0.85)
            rowFrame:SetBackdropBorderColor(0.20, 0.20, 0.24, 1)
        end

        -- Dungeon icon
        local icon = rowFrame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(34, 34)
        icon:SetPoint("LEFT", rowFrame, "LEFT", 6, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        rowFrame.icon = icon

        -- Dungeon Name
        local nameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 6, -2)
        nameText:SetPoint("RIGHT", rowFrame, "RIGHT", -68, 0)
        nameText:SetJustifyH("LEFT")
        nameText:SetWordWrap(false)
        rowFrame.nameText = nameText

        -- Best Record
        local recText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        recText:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 6, 2)
        recText:SetJustifyH("LEFT")
        rowFrame.recText = recText

        -- Secure Teleport Button (InCombat safe)
        local tpBtn = CreateFrame("Button", nil, rowFrame, "SecureActionButtonTemplate, BackdropTemplate")
        tpBtn:SetSize(62, 22)
        tpBtn:SetPoint("RIGHT", rowFrame, "RIGHT", -6, 0)
        tpBtn:RegisterForClicks("AnyUp", "AnyDown")
        tpBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        tpBtn:SetBackdropColor(0.0, 0.45, 0.55, 0.85)
        tpBtn:SetBackdropBorderColor(0.0, 0.85, 0.95, 1)

        local tpText = tpBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tpText:SetPoint("CENTER")
        tpText:SetText(L["HUB_BTN_TELEPORT"] or "Teleport")
        tpBtn.text = tpText

        rowFrame.tpBtn = tpBtn
        f.dungeonRows[i] = rowFrame
    end

    -- ==========================================================
    -- SECTION 2: PARTY KEYSTONE MATRIX (Bottom Half)
    -- ==========================================================
    local secKeys = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    secKeys:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -282)
    secKeys:SetText("|cffffcc00" .. (L["HUB_SEC_PARTY_KEYS"] or "Matriz de Llaves del Grupo") .. "|r")

    local keysContainer = CreateFrame("Frame", nil, f)
    keysContainer:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -302)
    keysContainer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 46)
    f.keysContainer = keysContainer

    f.partyRows = {}
    for i = 1, 5 do
        local pRow = CreateFrame("Frame", nil, keysContainer, "BackdropTemplate")
        pRow:SetHeight(24)
        pRow:SetPoint("TOPLEFT", keysContainer, "TOPLEFT", 0, -((i - 1) * 26))
        pRow:SetPoint("TOPRIGHT", keysContainer, "TOPRIGHT", 0, -((i - 1) * 26))
        pRow:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        pRow:SetBackdropColor(0.09, 0.09, 0.12, 0.8)
        pRow:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

        -- Role Icon
        local roleIcon = pRow:CreateTexture(nil, "ARTWORK")
        roleIcon:SetSize(16, 16)
        roleIcon:SetPoint("LEFT", pRow, "LEFT", 6, 0)
        pRow.roleIcon = roleIcon

        -- Player Name
        local pName = pRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        pName:SetPoint("LEFT", roleIcon, "RIGHT", 6, 0)
        pName:SetWidth(140)
        pName:SetJustifyH("LEFT")
        pRow.pName = pName

        -- Dungeon & Key level
        local keyText = pRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        keyText:SetPoint("RIGHT", pRow, "RIGHT", -8, 0)
        keyText:SetJustifyH("RIGHT")
        pRow.keyText = keyText

        f.partyRows[i] = pRow
    end

    -- Bottom Action Buttons
    local btnPost = DQ.UI:CreateFlatButton(f, L["HUB_BTN_POST_KEYS"] or "Publicar en Chat", 120, 24)
    btnPost:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 12)
    btnPost:SetScript("OnClick", function()
        DQ.CommandHub:AnnouncePartyKeys()
    end)

    local btnRefresh = DQ.UI:CreateFlatButton(f, L["HUB_BTN_REFRESH"] or "Actualizar", 100, 24)
    btnRefresh:SetPoint("LEFT", btnPost, "RIGHT", 8, 0)
    btnRefresh:SetScript("OnClick", function()
        RequestPartyKeys()
        DQ.CommandHub:RefreshUI()
    end)

    local btnVault = DQ.UI:CreateFlatButton(f, "Gran Bóveda", 100, 24)
    btnVault:SetPoint("RIGHT", f, "BOTTOMRIGHT", -14, 12)
    btnVault:SetScript("OnClick", function()
        if DQ.Util and DQ.Util.ToggleGreatVault then
            DQ.Util.ToggleGreatVault()
        end
    end)

    hubFrame = f
    return hubFrame
end

-- Refreshes the Command Hub UI
function DQ.CommandHub:RefreshUI()
    local f = CreateCommandHubFrame()
    if not f or not f:IsShown() then return end

    RebuildTeleportLookups()
    local L = DQ.L or {}

    -- 1. Refresh Seasonal Dungeons
    local mapList = (C_ChallengeMode and C_ChallengeMode.GetMapTable and C_ChallengeMode.GetMapTable()) or {}
    for i = 1, 8 do
        local row = f.dungeonRows[i]
        local mapID = mapList[i]
        local portalEntry = SEASON_PORTALS[i]

        local targetSpellID = portalEntry and portalEntry.spellID
        local displayName = portalEntry and (portalEntry.defaultName or portalEntry.names[1]) or "Dungeon"
        local displayIcon = "Interface\\Icons\\INV_Misc_QuestionMark"

        if mapID and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
            local name, _, _, icon = C_ChallengeMode.GetMapUIInfo(mapID)
            if name then displayName = name end
            if icon then displayIcon = icon end
            if MAP_TO_SPELL[mapID] then targetSpellID = MAP_TO_SPELL[mapID] end
        elseif portalEntry and portalEntry.dungeonID and GetLFGDungeonInfo then
            local ok, localName, _, _, _, _, _, _, _, _, icon = pcall(GetLFGDungeonInfo, portalEntry.dungeonID)
            if ok and localName and localName ~= "" then
                displayName = localName
            end
            if icon then displayIcon = icon end
        end

        if displayIcon == "Interface\\Icons\\INV_Misc_QuestionMark" and targetSpellID and C_Spell and C_Spell.GetSpellTexture then
            displayIcon = C_Spell.GetSpellTexture(targetSpellID) or displayIcon
        end

        row.icon:SetTexture(displayIcon)
        row.nameText:SetText(displayName)

        -- Personal Best Record
        local bestStr = L["HUB_NO_RECORD"] or "Sin récord"
        if mapID and C_MythicPlus and C_MythicPlus.GetSeasonBestForMap then
            local intime, overtime = C_MythicPlus.GetSeasonBestForMap(mapID)
            if intime and intime.level and intime.level > 0 then
                bestStr = string.format("|cff00ff88+%d|r (%dm %02ds)", intime.level, math.floor(intime.durationSec / 60), intime.durationSec % 60)
            elseif overtime and overtime.level and overtime.level > 0 then
                bestStr = string.format("|cffffaa00+%d|r (Agotado)", overtime.level)
            end
        end
        row.recText:SetText(bestStr)

        -- Secure Teleport Button configuration (only configure out of combat)
        if not InCombatLockdown() then
            local isKnown = IsTeleportLearned(targetSpellID)
            row.tpBtn:SetAttribute("type", "spell")
            row.tpBtn:SetAttribute("spell", targetSpellID)

            if isKnown then
                row.tpBtn:SetBackdropColor(0.0, 0.45, 0.55, 0.85)
                row.tpBtn:SetBackdropBorderColor(0.0, 0.85, 0.95, 1)
                row.tpBtn.text:SetTextColor(1, 1, 1, 1)
                row.tpBtn:Enable()
            else
                row.tpBtn:SetBackdropColor(0.12, 0.12, 0.15, 0.5)
                row.tpBtn:SetBackdropBorderColor(0.25, 0.25, 0.28, 0.8)
                row.tpBtn.text:SetTextColor(0.45, 0.45, 0.45, 1)
                row.tpBtn:Disable()
            end
        end

        row:Show()
    end

    -- 2. Refresh Party Keystones
    local members = {}
    if IsInGroup() then
        local prefix = IsInRaid() and "raid" or "party"
        local count = GetNumGroupMembers()
        for i = 1, count do
            local unit = (prefix == "party" and i == count) and "player" or (prefix .. i)
            local name = UnitName(unit)
            if name then
                local _, class = UnitClass(unit)
                local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit) or "NONE"
                table.insert(members, { unit = unit, name = name, class = class, role = role })
            end
        end
    else
        local _, class = UnitClass("player")
        table.insert(members, { unit = "player", name = UnitName("player"), class = class, role = "DAMAGER" })
    end

    for i = 1, 5 do
        local pRow = f.partyRows[i]
        local member = members[i]
        if member then
            -- Set Role Icon
            local roleTex = "Interface\\LFGFRAME\\LFGROLE_DPS"
            if member.role == "TANK" then
                roleTex = "Interface\\LFGFRAME\\LFGROLE_TANK"
            elseif member.role == "HEALER" then
                roleTex = "Interface\\LFGFRAME\\LFGROLE_HEALER"
            end
            pRow.roleIcon:SetTexture(roleTex)

            -- Class colored name
            local nameStr = DQ.Util and DQ.Util.ClassColorName and DQ.Util.ClassColorName(member.name, member.class)
            if not nameStr then
                nameStr = member.name
                if member.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[member.class] then
                    local cc = RAID_CLASS_COLORS[member.class]
                    nameStr = string.format("|cff%02x%02x%02x%s|r", cc.r * 255, cc.g * 255, cc.b * 255, member.name)
                end
            end
            pRow.pName:SetText(nameStr)

            -- Key Info
            local keyInfo = partyKeys[member.name]
            if UnitIsUnit(member.unit, "player") then
                local myMap, myLvl = GetPlayerKeystone()
                if myLvl > 0 then
                    local myName = (C_ChallengeMode and C_ChallengeMode.GetMapUIInfo and C_ChallengeMode.GetMapUIInfo(myMap)) or "Keystone"
                    pRow.keyText:SetText(string.format("|cffffffff%s|r  |cffffd100+%d|r", myName, myLvl))
                else
                    pRow.keyText:SetText("|cff888888" .. (L["HUB_NO_KEY"] or "Sin piedra") .. "|r")
                end
            elseif keyInfo and keyInfo.level and keyInfo.level > 0 then
                pRow.keyText:SetText(string.format("|cffffffff%s|r  |cffffd100+%d|r", keyInfo.name or "Dungeon", keyInfo.level))
            else
                pRow.keyText:SetText("|cff888888" .. (L["HUB_NO_KEY"] or "Sin piedra") .. "|r")
            end

            pRow:Show()
        else
            pRow:Hide()
        end
    end
end

-- Announces group keystones to party/raid chat
function DQ.CommandHub:AnnouncePartyKeys()
    if not IsInGroup() then return end
    local L = DQ.L or {}

    local myMap, myLvl = GetPlayerKeystone()
    local myDungeon = (myMap > 0 and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo and C_ChallengeMode.GetMapUIInfo(myMap)) or nil

    local entries = {}
    if myLvl > 0 and myDungeon then
        table.insert(entries, string.format("%s (+%d %s)", UnitName("player"), myLvl, myDungeon))
    end

    for pName, k in pairs(partyKeys) do
        if k.level and k.level > 0 and pName ~= UnitName("player") then
            table.insert(entries, string.format("%s (+%d %s)", pName, k.level, k.name or "Dungeon"))
        end
    end

    if #entries > 0 then
        local header = L["HUB_KEYS_ANNOUNCE_HDR"] or "DistractionQoL — Llaves del Grupo:"
        local msg = header .. " " .. table.concat(entries, " | ")
        local channel = IsInRaid() and "RAID" or "PARTY"
        if SendChatMessage then
            pcall(SendChatMessage, msg, channel)
        end
    end
end

-- Toggles Command Hub window visibility
function DQ.CommandHub:Toggle()
    if DQ.Config and DQ.Config:Get("mythicPlus", "commandHub") == false then
        local L = DQ.L or {}
        local msg = L["HUB_DISABLED"] or "El Centro de Mazmorras M+ está desactivado en la configuración."
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00e5ff[DistractionQoL]|r " .. msg)
        end
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        local L = DQ.L or {}
        local msg = "|cffff3333" .. (L["MSG_BAG_SORT_COMBAT"] or "No se puede abrir en combate.") .. "|r"
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00e5ff[DistractionQoL]|r " .. msg)
        end
        return
    end

    local f = CreateCommandHubFrame()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
        RequestPartyKeys()
        self:RefreshUI()
    end
end

function DQ.CommandHub:Init()
    -- Register addon message prefix for keystone sync
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix("DQ_KEYS")
    end

    RebuildTeleportLookups()

    local rosterTimer = nil
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_ADDON")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:RegisterEvent("CHALLENGE_MODE_START")
    f:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")

    f:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
        if event == "CHAT_MSG_ADDON" and prefix == "DQ_KEYS" then
            local shortSender = sender and sender:match("^([^-]+)") or sender
            if msg == "REQ_KEYS" then
                BroadcastOwnKey()
            elseif msg and msg:find("^MYKEY:") then
                local _, mapIDStr, levelStr = strsplit(":", msg)
                local mapID = tonumber(mapIDStr) or 0
                local level = tonumber(levelStr) or 0
                local mapName = "Dungeon"
                if mapID > 0 and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
                    mapName = C_ChallengeMode.GetMapUIInfo(mapID) or "Dungeon"
                end
                if shortSender and level > 0 then
                    partyKeys[shortSender] = {
                        mapID = mapID,
                        level = level,
                        name = mapName,
                    }
                    if hubFrame and hubFrame:IsShown() then
                        DQ.CommandHub:RefreshUI()
                    end
                end
            end

        elseif event == "PLAYER_REGEN_DISABLED" then
            if hubFrame and hubFrame:IsShown() then
                hubFrame:Hide()
            end

        elseif event == "GROUP_ROSTER_UPDATE" then
            if IsInGroup() then
                if not rosterTimer then
                    rosterTimer = C_Timer.NewTimer(1.5, function()
                        rosterTimer = nil
                        RequestPartyKeys()
                    end)
                end
            else
                if rosterTimer then rosterTimer:Cancel() rosterTimer = nil end
                wipe(partyKeys)
            end
            if hubFrame and hubFrame:IsShown() then
                DQ.CommandHub:RefreshUI()
            end
        end
    end)

    -- Intercept /keys if not taken
    if not SlashCmdList["KEYS"] then
        SLASH_KEYS1 = "/keys"
        SlashCmdList["KEYS"] = function()
            DQ.CommandHub:Toggle()
        end
    end
end
