-- Detection.lua
-- Detection module for content type, difficulty, combat states, and raider consumables
-- Fully event-driven, zero polling overhead

local addonName, DQ = ...

DQ.Detection = {
    simMode = false, -- Temporarily enabled during /qol sim
}

-- Checks if the player is currently dead or in manual simulation mode
function DQ.Detection:IsDeadOrSim()
    if self.simMode then
        return true
    end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
        return true
    end
    if UnitIsDead and UnitIsDead("player") then
        return true
    end
    return false
end

-- Determines if current environment matches user protection settings for spirit release
function DQ.Detection:ShouldProtect()
    -- Always protect when in manual simulation mode
    if self.simMode then
        return true
    end

    -- ABSOLUTE SAFETY GUARD: Player MUST be dead or ghost!
    -- If player is alive, spirit release protection must NEVER trigger!
    if not self:IsDeadOrSim() then
        return false
    end

    local inInstance, instanceType = IsInInstance()

    -- 1. OPEN WORLD
    if not inInstance or instanceType == "none" then
        return DQ.Config:Get("releaseGuard", "openWorld") == true
    end

    -- 2. DUNGEONS & DELVES / SCENARIOS (e.g. Labyrinth of Kindo'jan in 12.1.5)
    if instanceType == "party" or instanceType == "scenario" then
        return DQ.Config:Get("releaseGuard", "dungeons") == true
    end

    -- 3. RAIDS
    if instanceType == "raid" or (IsInRaid and IsInRaid()) then
        local raidsEnabled = DQ.Config:Get("releaseGuard", "raids", "enabled")
        if not raidsEnabled then
            return false
        end

        local _, _, difficultyID, difficultyName = GetInstanceInfo()
        local diffName = (difficultyName or ""):lower()

        -- Identify Mythic difficulty
        if difficultyID == 16 or diffName:find("mythic") or diffName:find("mítico") or diffName:find("mitico") then
            return DQ.Config:Get("releaseGuard", "raids", "mythic") == true
        end

        -- Identify Heroic difficulty
        if difficultyID == 15 or difficultyID == 5 or difficultyID == 6 or diffName:find("heroic") or diffName:find("heroico") or diffName:find("heroica") then
            return DQ.Config:Get("releaseGuard", "raids", "heroic") == true
        end

        -- Identify Normal difficulty
        if difficultyID == 14 or difficultyID == 3 or difficultyID == 4 or diffName:find("normal") then
            return DQ.Config:Get("releaseGuard", "raids", "normal") == true
        end

        -- Other raid types (LFR / Raid Finder, Timewalking, etc.)
        return true
    end

    return false
end

-- Accurately detects if player, party, raid or encounter is in active combat.
-- Crucial for detecting Battle Resurrections when player is dead (UnitAffectingCombat("player") is false).
function DQ.Detection:IsCombatActive()
    -- 1. Direct player combat flags
    if InCombatLockdown and InCombatLockdown() then
        return true
    end
    if UnitAffectingCombat and UnitAffectingCombat("player") then
        return true
    end

    -- 2. Active Dungeon / Raid boss encounter
    if IsEncounterInProgress and IsEncounterInProgress() then
        return true
    end
    if C_Instance and C_Instance.IsInEncounter and C_Instance.IsInEncounter() then
        return true
    end

    -- 3. Active boss units (boss1..boss8)
    for i = 1, 8 do
        local boss = "boss" .. i
        if UnitExists(boss) and (UnitAffectingCombat(boss) or not UnitIsDead(boss)) then
            return true
        end
    end

    -- 4. Living Raid members in combat
    if IsInRaid and IsInRaid() then
        local num = GetNumGroupMembers and GetNumGroupMembers() or 0
        for i = 1, num do
            local u = "raid" .. i
            if UnitExists(u) and not UnitIsUnit(u, "player") and not UnitIsDeadOrGhost(u) and UnitAffectingCombat(u) then
                return true
            end
        end
    -- 5. Living Party members in combat (Dungeons, Mythic+)
    elseif IsInGroup and IsInGroup() then
        local num = GetNumSubgroupMembers and GetNumSubgroupMembers() or 4
        for i = 1, num do
            local u = "party" .. i
            if UnitExists(u) and not UnitIsUnit(u, "player") and not UnitIsDeadOrGhost(u) and UnitAffectingCombat(u) then
                return true
            end
        end
    end

    -- 6. Player's pet or target/focus in combat
    if UnitExists("pet") and UnitAffectingCombat("pet") then
        return true
    end
    if UnitExists("target") and UnitAffectingCombat("target") then
        return true
    end
    if UnitExists("focus") and UnitAffectingCombat("focus") then
        return true
    end

    return false
end

-- Checks if player is missing critical raid consumables (Flask, Food, Rune, Weapon Enchant)
-- Runs strictly on demand (e.g. READY_CHECK) with microsecond execution time.
function DQ.Detection:CheckPlayerConsumables()
    local hasFood = false
    local hasFlask = false
    local hasRune = false

    -- Inspect player helpful auras (pcall protected against Midnight secret values)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local i = 1
        while true do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
            if not ok or not aura then break end

            local name = aura.name or ""
            local lowerName = name:lower()
            local icon = aura.icon or 0

            -- 1. Food (Well Fed)
            -- Known food icons: 134062 (spell_misc_food), 136000, 134063, or name matches
            if icon == 134062 or icon == 136000 or icon == 134063 or
               lowerName:find("well fed") or lowerName:find("bien alimentado") or
               lowerName:find("aliment") or lowerName:find("satt") then
                hasFood = true
            end

            -- 2. Flask / Phial
            -- Modern retail phials, classic flasks: icon or keywords (safe against secret values)
            if lowerName:find("flask") or lowerName:find("frasco") or
               lowerName:find("phial") or lowerName:find("fial") or
               lowerName:find("elixir") or icon == 463853 or icon == 463854 then
                hasFlask = true
            end

            -- 3. Augment Rune
            if lowerName:find("rune") or lowerName:find("runa") or lowerName:find("augment") or lowerName:find("aumento") then
                hasRune = true
            end

            i = i + 1
        end
    end

    -- 4. Temporary Weapon Enchant (Oil, Stone, Poison, Shadowcore Oil)
    local hasWeaponEnchant = true
    if GetWeaponEnchantInfo then
        local hasMH = GetInventoryItemID and GetInventoryItemID("player", 16)
        if hasMH then
            local hasMHEnh = GetWeaponEnchantInfo()
            if not hasMHEnh then
                hasWeaponEnchant = false
            end
        end
    end

    local missing = {}
    local L = DQ.L or {}
    if not hasFood then table.insert(missing, L["FOOD_BUFF"] or "Comida (Well Fed)") end
    if not hasFlask then table.insert(missing, L["FLASK_BUFF"] or "Frasco / Phial") end
    if not hasWeaponEnchant then table.insert(missing, L["WEAPON_BUFF"] or "Aceite/Piedra de Arma") end
    -- Note: Rune is typically optional in normal/heroic, but tracked for mythic
    if not hasRune and IsInRaid and IsInRaid() then
        -- Only flag rune in mythic raid
        local _, _, diffID = GetInstanceInfo()
        if diffID == 16 then
            table.insert(missing, L["RUNE_BUFF"] or "Runa de Aumento")
        end
    end

    return missing
end

-- Checks for consumables that are about to expire (e.g. less than thresholdSeconds remaining)
function DQ.Detection:CheckExpiringConsumables(thresholdSeconds)
    thresholdSeconds = thresholdSeconds or 300
    local expiring = {}
    local now = GetTime and GetTime() or 0
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return expiring end

    local i = 1
    while true do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
        if not ok or not aura then break end

        local exp = aura.expirationTime or 0
        if exp > 0 and (exp - now) > 0 and (exp - now) <= thresholdSeconds then
            local remMins = math.ceil((exp - now) / 60)
            local name = aura.name or "Consumible"
            local lowerName = name:lower()
            local icon = aura.icon or 0

            local isConsumable = false
            if icon == 134062 or icon == 136000 or icon == 134063 or
               lowerName:find("well fed") or lowerName:find("bien alimentado") or
               lowerName:find("aliment") or lowerName:find("satt") then
                isConsumable = true
            elseif lowerName:find("flask") or lowerName:find("frasco") or
                   lowerName:find("phial") or lowerName:find("fial") or
                   lowerName:find("elixir") or icon == 463853 or icon == 463854 then
                isConsumable = true
            elseif lowerName:find("rune") or lowerName:find("runa") or lowerName:find("augment") or lowerName:find("aumento") then
                isConsumable = true
            end

            if isConsumable then
                table.insert(expiring, { name = name, minutes = remMins })
            end
        end
        i = i + 1
    end

    return expiring
end

