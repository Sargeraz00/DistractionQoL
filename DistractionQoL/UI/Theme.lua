-- Theme.lua
-- Centralized visual design system, obsidian color tokens, and backdrop definitions for DistractionQoL
-- Clean Obsidian Flat aesthetic aligned with modern competitive WoW UI (EllesmereUI & ElvUI compatible).

local addonName, DQ = ...

DQ.Theme = DQ.Theme or {}

-- Standard 1px Flat Border Backdrop definition
DQ.Theme.Backdrop1px = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

-- Curated Color Palette
DQ.Theme.Colors = {
    -- Backgrounds
    bgWindow       = { 0.06, 0.06, 0.08, 0.96 },
    bgSidebar      = { 0.05, 0.05, 0.07, 0.98 },
    bgCard         = { 0.10, 0.10, 0.14, 0.85 },
    bgCardHover    = { 0.14, 0.14, 0.18, 0.95 },
    bgCardAlt      = { 0.08, 0.08, 0.11, 0.85 },
    bgButton       = { 0.12, 0.12, 0.16, 0.95 },
    bgButtonHover  = { 0.18, 0.18, 0.24, 1.00 },

    -- Borders
    borderSubtle   = { 0.20, 0.20, 0.24, 1.00 },
    borderCard     = { 0.22, 0.22, 0.26, 1.00 },
    borderAccent   = { 0.00, 0.85, 0.95, 1.00 }, -- Electric Cyan
    borderPurple   = { 0.65, 0.35, 0.95, 1.00 }, -- Royal Purple

    -- Accents
    accentCyan     = { 0.00, 0.85, 0.95, 1.00 },
    accentCyanDim  = { 0.00, 0.45, 0.55, 0.85 },
    accentPurple   = { 0.65, 0.35, 0.95, 1.00 },
    accentGold     = { 1.00, 0.82, 0.00, 1.00 },

    -- Status & Feedback
    statusSuccess  = { 0.00, 1.00, 0.53, 1.00 },
    statusError    = { 1.00, 0.27, 0.27, 1.00 },
    statusWarning  = { 1.00, 0.67, 0.00, 1.00 },

    -- Text
    textNormal     = { 0.90, 0.90, 0.92, 1.00 },
    textMuted      = { 0.65, 0.65, 0.70, 1.00 },
    textDisabled   = { 0.45, 0.45, 0.50, 1.00 },
    textCyan       = { 0.00, 0.90, 1.00, 1.00 },
}

-- Hex Strings for in-line font coloring
DQ.Theme.Hex = {
    cyan    = "ff00e5ff",
    cyanDim = "ff0099b8",
    purple  = "ffb15cff",
    gold    = "ffffcc00",
    green   = "ff00ff88",
    red     = "ffff4444",
    white   = "ffffffff",
    muted   = "ff888888",
}

-- Applies flat window backdrop
function DQ.Theme.ApplyWindowStyle(frame)
    frame:SetBackdrop(DQ.Theme.Backdrop1px)
    local c = DQ.Theme.Colors
    frame:SetBackdropColor(unpack(c.bgWindow))
    frame:SetBackdropBorderColor(unpack(c.borderCard))
end

-- Applies flat card/row backdrop
function DQ.Theme.ApplyCardStyle(frame, alt)
    frame:SetBackdrop(DQ.Theme.Backdrop1px)
    local c = DQ.Theme.Colors
    local bg = alt and c.bgCardAlt or c.bgCard
    frame:SetBackdropColor(unpack(bg))
    frame:SetBackdropBorderColor(unpack(c.borderSubtle))
end

-- Applies standard flat button backdrop
function DQ.Theme.ApplyButtonStyle(btn, isAccent)
    btn:SetBackdrop(DQ.Theme.Backdrop1px)
    local c = DQ.Theme.Colors
    if isAccent then
        btn:SetBackdropColor(unpack(c.accentCyanDim))
        btn:SetBackdropBorderColor(unpack(c.borderAccent))
    else
        btn:SetBackdropColor(unpack(c.bgButton))
        btn:SetBackdropBorderColor(unpack(c.borderSubtle))
    end
end
