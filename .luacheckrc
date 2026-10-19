-- .luacheckrc
-- Static analysis configuration for DistractionQoL (World of Warcraft 12.x / Midnight)

std = "lua51"
max_line_length = 200

-- Ignore unused argument variables starting with an underscore
ignore = { "212/_.*" }

-- Allow globals provided by World of Warcraft FrameXML engine and Blizzard APIs
read_globals = {
    -- FrameXML Primitives
    "UIParent",
    "CreateFrame",
    "hooksecurefunc",
    "issecretvalue",
    "InCombatLockdown",
    "UnitClass",
    "UnitName",
    "UnitExists",
    "UnitIsUnit",
    "UnitIsDead",
    "UnitIsDeadOrGhost",
    "UnitAffectingCombat",
    "UnitGroupRolesAssigned",
    "GetNumGroupMembers",
    "IsInGroup",
    "IsInRaid",
    "IsInInstance",
    "GetInstanceInfo",
    "GetLocale",
    "GetInventoryItemLink",
    "GetInventoryItemID",
    "GetInventoryItemTexture",
    "GetItemQualityColor",
    "GetLFGDungeonInfo",
    "PlaySound",
    "PlaySoundFile",
    "SOUNDKIT",
    "SendChatMessage",
    "DEFAULT_CHAT_FRAME",
    "GameTooltip",
    "StaticPopupDialogs",
    "StaticPopup_Show",
    "StaticPopup_Hide",
    "StaticPopup_FindVisible",
    "StaticPopup_Visible",
    "HideUIPanel",
    "SlashCmdList",
    "Settings",
    "SettingsPanel",
    "WeeklyRewardsFrame",
    "IsShiftKeyDown",
    "IsControlKeyDown",
    "IsAltKeyDown",
    "CursorHasItem",
    "ClearCursor",
    "wipe",
    "unpack",

    -- Namespaces
    "C_Item",
    "C_Container",
    "C_LFGList",
    "C_ChallengeMode",
    "C_AddOns",
    "C_Timer",
    "C_Spell",
    "Enum",
    "RAID_CLASS_COLORS",

    -- Addon Globals / SavedVariables
    "DistractionQoLDB",
    "BaneBurroReminderDB",
}

-- Tests directory overrides
files["tests/"] = {
    std = "+mock_wow",
    read_globals = { "describe", "it", "assert" },
}
