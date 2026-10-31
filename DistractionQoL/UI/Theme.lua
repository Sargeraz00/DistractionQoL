-- Theme.lua
-- Centralized visual design system, obsidian color tokens, and backdrop definitions for DistractionQoL
-- Clean Obsidian Flat aesthetic aligned with modern competitive WoW UI (EllesmereUI & ElvUI compatible).

local addonName, DQ = ...

DQ.Theme = DQ.Theme or {}

-- Standard 1px Flat Border Backdrop definition
DQ.Theme.Backdrop1px = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false,
    tileSize = 0,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

-- Curated Color Palette (Legacy & Utility)
DQ.Theme.Colors = {
    -- Backgrounds
    bgWindow       = { 0.07, 0.07, 0.09, 0.98 },
    bgSidebar      = { 0.09, 0.09, 0.11, 0.98 },
    bgCard         = { 0.14, 0.14, 0.17, 0.95 },
    bgCardHover    = { 0.18, 0.18, 0.22, 1.00 },
    bgCardAlt      = { 0.11, 0.11, 0.14, 0.95 },
    bgButton       = { 0.16, 0.16, 0.20, 0.95 },
    bgButtonHover  = { 0.22, 0.22, 0.28, 1.00 },

    -- Borders
    borderSubtle   = { 0.22, 0.23, 0.28, 0.60 },
    borderCard     = { 0.25, 0.26, 0.32, 0.70 },
    borderAccent   = { 0.00, 0.90, 1.00, 1.00 }, -- M3 Electric Cyan
    borderPurple   = { 0.78, 0.75, 1.00, 1.00 }, -- M3 Soft Lavender

    -- Accents
    accentCyan     = { 0.00, 0.90, 1.00, 1.00 },
    accentCyanDim  = { 0.00, 0.40, 0.48, 0.90 },
    accentPurple   = { 0.78, 0.75, 1.00, 1.00 },
    accentGold     = { 1.00, 0.82, 0.40, 1.00 },

    -- Status & Feedback
    statusSuccess  = { 0.00, 1.00, 0.55, 1.00 },
    statusError    = { 1.00, 0.45, 0.45, 1.00 },
    statusWarning  = { 1.00, 0.72, 0.30, 1.00 },

    -- Text
    textNormal     = { 0.90, 0.91, 0.94, 1.00 },
    textMuted      = { 0.62, 0.64, 0.70, 1.00 },
    textDisabled   = { 0.45, 0.46, 0.52, 1.00 },
    textCyan       = { 0.00, 0.90, 1.00, 1.00 },
}

-- ==========================================================
-- MATERIAL DESIGN 3 (M3) DESIGN SYSTEM - BLUE GREY PALETTE
-- Exact Palette: #000a12 | #102027 | #263238 | #37474f | #4f5b62
-- ==========================================================
DQ.Theme.M3 = {
    -- Tonal Surface Roles (Material Blue Grey)
    surface                  = { 0.00, 0.04, 0.07, 0.98 }, -- #000a12 - Darkest Navy Base Window Surface
    surfaceDim               = { 0.00, 0.02, 0.05, 0.98 }, -- Recessed background
    surfaceContainerLowest   = { 0.00, 0.03, 0.06, 0.98 }, -- App bar deep background
    surfaceContainerLow      = { 0.06, 0.13, 0.15, 0.98 }, -- #102027 - Navigation Rail / Drawer & Action Bar
    surfaceContainer         = { 0.15, 0.20, 0.22, 0.98 }, -- #263238 - Content Canvas Base
    surfaceContainerHigh     = { 0.22, 0.28, 0.31, 0.98 }, -- #37474f - Cards / Elevated Sections / Tonal Btns
    surfaceContainerHighest  = { 0.31, 0.36, 0.38, 1.00 }, -- #4f5b62 - Hover State Layers / Chip Containers

    -- Primary Brand (M3 Electric Mint / Cyan Accent)
    primary                  = { 0.00, 0.90, 1.00, 1.00 }, -- #00e5ff
    onPrimary                = { 0.00, 0.12, 0.15, 1.00 }, -- Crisp contrast text on filled primary (#001f26)
    primaryContainer         = { 0.00, 0.28, 0.32, 0.95 }, -- #004752 - Active navigation pill container
    onPrimaryContainer       = { 0.65, 0.96, 0.98, 1.00 }, -- #a6f5fa - Active tab label & icon

    -- Secondary Accent (M3 Soft Lavender)
    secondary                = { 0.78, 0.75, 1.00, 1.00 }, -- #c7bfff
    onSecondary              = { 0.19, 0.15, 0.38, 1.00 },
    secondaryContainer       = { 0.22, 0.28, 0.31, 0.95 }, -- #37474f - Tonal secondary container
    onSecondaryContainer     = { 0.90, 0.93, 0.96, 1.00 }, -- Soft bright text on secondary container

    -- Status & Alerts
    error                    = { 1.00, 0.55, 0.55, 1.00 },
    errorContainer           = { 0.32, 0.10, 0.10, 0.95 },
    onErrorContainer         = { 1.00, 0.85, 0.85, 1.00 },
    success                  = { 0.00, 1.00, 0.55, 1.00 },
    successContainer         = { 0.06, 0.28, 0.16, 0.95 },

    -- Outlines & Dividers (Silky 1px M3 Blue Grey contours)
    outline                  = { 0.31, 0.36, 0.38, 0.55 }, -- #4f5b62 with soft alpha
    outlineVariant           = { 0.22, 0.28, 0.31, 0.40 }, -- #37474f with subtle alpha

    -- Typography Emphases
    onSurface                = { 0.92, 0.94, 0.96, 1.00 }, -- High-emphasis white
    onSurfaceVariant         = { 0.65, 0.70, 0.74, 1.00 }, -- Medium-emphasis Blue-Grey text
    outlineText              = { 0.45, 0.50, 0.54, 1.00 }, -- Subtle captions
}

-- ==========================================================
-- INTER TYPOGRAPHY SYSTEM (Open Font License)
-- ==========================================================
DQ.Theme.FontRegular  = "Interface\\AddOns\\" .. (addonName or "DistractionQoL") .. "\\Media\\Fonts\\Inter-Regular.ttf"
DQ.Theme.FontBold     = "Interface\\AddOns\\" .. (addonName or "DistractionQoL") .. "\\Media\\Fonts\\Inter-Bold.ttf"
DQ.Theme.FontSemiBold = "Interface\\AddOns\\" .. (addonName or "DistractionQoL") .. "\\Media\\Fonts\\Inter-SemiBold.ttf"

function DQ.Theme.GetFont(weight)
    if weight == "bold" then
        return DQ.Theme.FontBold
    elseif weight == "semibold" then
        return DQ.Theme.FontSemiBold
    else
        return DQ.Theme.FontRegular
    end
end

-- Hex Strings for in-line font coloring
DQ.Theme.Hex = {
    cyan    = "ff00e5ff",
    cyanDim = "ff0099b8",
    purple  = "ffb15cff",
    gold    = "ffffcc00",
    green   = "ff00ff88",
    red     = "ffff4444",
    white   = "ffffffff",
    muted   = "ffa7b1b8",
}

-- Applies flat window backdrop
function DQ.Theme.ApplyWindowStyle(frame)
    frame:SetBackdrop(DQ.Theme.Backdrop1px)
    local m3 = DQ.Theme.M3
    frame:SetBackdropColor(unpack(m3.surface))
    frame:SetBackdropBorderColor(unpack(m3.outline))

    if not frame._dqSolidBg then
        local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        bg:SetColorTexture(unpack(m3.surface))
        frame._dqSolidBg = bg
    else
        frame._dqSolidBg:SetColorTexture(unpack(m3.surface))
    end
end

-- Applies M3 card surface backdrop
function DQ.Theme.ApplyCardStyle(frame, alt)
    frame:SetBackdrop(DQ.Theme.Backdrop1px)
    local m3 = DQ.Theme.M3
    local bg = alt and m3.surfaceContainer or m3.surfaceContainerHigh
    frame:SetBackdropColor(unpack(bg))
    frame:SetBackdropBorderColor(unpack(m3.outlineVariant))

    if not frame._dqSolidBg then
        local solid = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
        solid:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        solid:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        solid:SetColorTexture(unpack(bg))
        frame._dqSolidBg = solid
    else
        frame._dqSolidBg:SetColorTexture(unpack(bg))
    end
end

-- Applies standard flat button backdrop
function DQ.Theme.ApplyButtonStyle(btn, isAccent)
    btn:SetBackdrop(DQ.Theme.Backdrop1px)
    local m3 = DQ.Theme.M3
    if isAccent then
        btn:SetBackdropColor(unpack(m3.primary))
        btn:SetBackdropBorderColor(unpack(m3.primary))
    else
        btn:SetBackdropColor(unpack(m3.secondaryContainer))
        btn:SetBackdropBorderColor(unpack(m3.outline))
    end
end

-- Applies crisp Inter font styling to a FontString with zero shadow bleed
function DQ.Theme.ApplyText(fontString, size, weight, color)
    if not fontString then return end
    local fontPath = DQ.Theme.GetFont(weight or "regular")
    fontString:SetFont(fontPath, size or 12, "")
    fontString:SetShadowOffset(0, 0)
    if color then
        fontString:SetTextColor(unpack(color))
    end
end
