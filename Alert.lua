-- Alert.lua
-- Visual warning frame and Bane.ogg audio playback module for DistractionQoL
-- Fully updated for WoW 12.1.0 (Midnight) API

local addonName, DQ = ...

DQ.Alert = {}

-- Audio paths with Ogg Vorbis and MP3 fallback
local soundPaths = {
    "Interface\\AddOns\\" .. addonName .. "\\Bane.ogg",
    "Interface\\AddOns\\" .. addonName .. "\\Bane.mp3",
    "Interface\\AddOns\\DistractionQoL\\Bane.ogg",
    "Interface\\AddOns\\DistractionQoL\\Bane.mp3",
}

-- Safe font resolver compatible with WoW 12.1.0
local function GetHeadlineFont()
    if GameFontNormalHuge and GameFontNormalHuge.GetFont then
        local f = GameFontNormalHuge:GetFont()
        if f then return f end
    end
    if GameFontNormal and GameFontNormal.GetFont then
        local f = GameFontNormal:GetFont()
        if f then return f end
    end
    if STANDARD_TEXT_FONT then return STANDARD_TEXT_FONT end
    return "Fonts\\FRIZQT__.TTF"
end

local function GetSubFont()
    if GameFontHighlightLarge and GameFontHighlightLarge.GetFont then
        local f = GameFontHighlightLarge:GetFont()
        if f then return f end
    end
    if GameFontHighlight and GameFontHighlight.GetFont then
        local f = GameFontHighlight:GetFont()
        if f then return f end
    end
    if STANDARD_TEXT_FONT then return STANDARD_TEXT_FONT end
    return "Fonts\\FRIZQT__.TTF"
end

-- Destroy legacy frame if lingering in memory
if _G["BaneBurroAlertFrame"] then
    _G["BaneBurroAlertFrame"]:Hide()
    _G["BaneBurroAlertFrame"]:SetScript("OnUpdate", nil)
    _G["BaneBurroAlertFrame"]:UnregisterAllEvents()
    _G["BaneBurroAlertFrame"] = nil
end

-- ==========================================================
-- GIANT WARNING FRAME CREATION
-- ==========================================================
local alertFrame = CreateFrame("Frame", "DistractionQoLAlertFrame", UIParent)
alertFrame:SetSize(860, 230)
alertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 160)
alertFrame:SetFrameStrata("FULLSCREEN_DIALOG")
alertFrame:SetToplevel(true)
alertFrame:Hide()

-- Dark translucent background for high visual contrast
local bg = alertFrame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0, 0, 0, 0.82)

-- Vibrant red top and bottom accent borders
local borderTop = alertFrame:CreateTexture(nil, "BORDER")
borderTop:SetPoint("TOPLEFT")
borderTop:SetPoint("TOPRIGHT")
borderTop:SetHeight(4)
borderTop:SetColorTexture(1, 0.15, 0.15, 1)

local borderBottom = alertFrame:CreateTexture(nil, "BORDER")
borderBottom:SetPoint("BOTTOMLEFT")
borderBottom:SetPoint("BOTTOMRIGHT")
borderBottom:SetHeight(4)
borderBottom:SetColorTexture(1, 0.15, 0.15, 1)

-- Giant headline text
local mainText = alertFrame:CreateFontString(nil, "OVERLAY")
mainText:SetFont(GetHeadlineFont(), 46, "THICKOUTLINE")
mainText:SetPoint("CENTER", alertFrame, "CENTER", 0, 24)
mainText:SetTextColor(1, 0.2, 0.2, 1) -- Bright Red
mainText:SetShadowColor(0, 0, 0, 1)
mainText:SetShadowOffset(3, -3)
mainText:SetText("¡BURRO, SONSO, NO LIBERES!")

-- Instructional subtext
local subText = alertFrame:CreateFontString(nil, "OVERLAY")
subText:SetFont(GetSubFont(), 18, "OUTLINE")
subText:SetPoint("BOTTOM", alertFrame, "BOTTOM", 0, 22)
subText:SetTextColor(1, 0.85, 0.2, 1) -- Bright Yellow / Gold
subText:SetText("¡Mantén presionado SHIFT y haz clic para liberar! (Hold SHIFT to release)")

-- Auto-hide timer
local timer = 0
alertFrame:SetScript("OnUpdate", function(self, elapsed)
    if timer > 0 then
        timer = timer - elapsed
        if timer <= 0 then
            self:Hide()
        end
    end
end)

-- ==========================================================
-- AUDIO PLAYBACK (OGG VORBIS + MP3 WITH MULTI-CHANNEL FALLBACK)
-- ==========================================================
function DQ.Alert:PlaySound()
    local soundEnabled = DQ.Config:Get("releaseGuard", "soundEnabled")
    if soundEnabled == nil then
        soundEnabled = DQ.Config:Get("soundEnabled")
    end
    if soundEnabled == false then return false end

    local channels = { "Master", "Dialog", "SFX" }

    for _, path in ipairs(soundPaths) do
        for _, channel in ipairs(channels) do
            local success, willPlay = pcall(PlaySoundFile, path, channel)
            if success and willPlay then
                return true
            end
        end
    end

    for _, path in ipairs(soundPaths) do
        local success, willPlay = pcall(PlaySoundFile, path)
        if success and willPlay then
            return true
        end
    end

    return false
end

-- ==========================================================
-- COMPLETE WARNING TRIGGER (VISUAL + AUDIO + CHAT)
-- Debounced to prevent accidental double triggering
-- ==========================================================
local lastAlertTime = 0

function DQ.Alert:Trigger()
    local now = GetTime and GetTime() or 0
    if (now - lastAlertTime) < 0.8 then
        return -- Debounce: prevent duplicate audio playback within 800ms
    end
    lastAlertTime = now

    local L = DQ.L or {}
    local titleText = L["ALERT_TITLE"] or "¡BURRO, SONSO, NO LIBERES!"
    local subTextMsg = L["ALERT_SUBTEXT"] or "¡Mantén presionado SHIFT y haz clic para liberar!"

    -- 1. Update text and show giant alert frame for 5 seconds
    mainText:SetText(titleText)
    subText:SetText(subTextMsg)
    timer = 5.0
    alertFrame:Show()

    -- 2. Play audio sound clip
    self:PlaySound()

    -- 3. Print message to default chat frame (Zero-taint, avoids Blizzard_RaidWarning)
    local prefix = "|cffff2222[DistractionQoL]|r "
    local msg = prefix .. "|cffff3333" .. titleText .. "|r |cffffcc00(" .. subTextMsg .. ")|r"
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    elseif print then
        print(msg)
    end
end
