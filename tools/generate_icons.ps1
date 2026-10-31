Add-Type -AssemblyName System.Drawing

$iconsDir = "c:\Users\Sargeraz\.gemini\antigravity-ide\scratch\DistractionQoL\DistractionQoL\Media\Icons"
if (-not (Test-Path $iconsDir)) {
    New-Item -ItemType Directory -Path $iconsDir -Force | Out-Null
}

function New-M3Icon([string]$fileName, [scriptblock]$drawAction) {
    $size = 64
    $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    & $drawAction $g $size

    $g.Flush()
    $g.Dispose()
    $fullPath = Join-Path $iconsDir $fileName
    $bmp.Save($fullPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Created icon: $fileName"
}

# 1. m3_release.png - Modern Guardian Shield with heart/core pulse
New-M3Icon "m3_release.png" {
    param($g, $size)
    $cyan = [System.Drawing.Color]::FromArgb(255, 0, 229, 255)
    $pen = New-Object System.Drawing.Pen($cyan, 3.5)
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

    # Shield outline
    $pts = @(
        (New-Object System.Drawing.PointF(32, 8)),
        (New-Object System.Drawing.PointF(54, 16)),
        (New-Object System.Drawing.PointF(54, 38)),
        (New-Object System.Drawing.PointF(32, 56)),
        (New-Object System.Drawing.PointF(10, 38)),
        (New-Object System.Drawing.PointF(10, 16))
    )
    $g.DrawPolygon($pen, $pts)

    # Core cross/guardian glyph inside
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 255, 255, 255))
    $g.FillRectangle($brush, 29, 20, 6, 24)
    $g.FillRectangle($brush, 20, 29, 24, 6)
    $pen.Dispose()
    $brush.Dispose()
}

# 2. m3_raidflow.png - Modern Flask & Rotary Aura
New-M3Icon "m3_raidflow.png" {
    param($g, $size)
    $cyan = [System.Drawing.Color]::FromArgb(255, 0, 229, 255)
    $pen = New-Object System.Drawing.Pen($cyan, 3.5)
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

    # Flask neck & body
    $pts = @(
        (New-Object System.Drawing.PointF(26, 10)),
        (New-Object System.Drawing.PointF(38, 10)),
        (New-Object System.Drawing.PointF(38, 22)),
        (New-Object System.Drawing.PointF(52, 48)),
        (New-Object System.Drawing.PointF(52, 54)),
        (New-Object System.Drawing.PointF(12, 54)),
        (New-Object System.Drawing.PointF(12, 48)),
        (New-Object System.Drawing.PointF(26, 22))
    )
    $g.DrawPolygon($pen, $pts)

    # Fluid fill level
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 255, 170))
    $fluidPts = @(
        (New-Object System.Drawing.PointF(16, 46)),
        (New-Object System.Drawing.PointF(48, 46)),
        (New-Object System.Drawing.PointF(48, 52)),
        (New-Object System.Drawing.PointF(16, 52))
    )
    $g.FillPolygon($brush, $fluidPts)

    # Sparkle bubble
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $g.FillEllipse($whiteBrush, 30, 36, 6, 6)
    $pen.Dispose()
    $brush.Dispose()
    $whiteBrush.Dispose()
}

# 3. m3_automation.png - Modern Lightning Circuit Bolt
New-M3Icon "m3_automation.png" {
    param($g, $size)
    $cyan = [System.Drawing.Color]::FromArgb(255, 0, 229, 255)
    $brush = New-Object System.Drawing.SolidBrush($cyan)

    $boltPts = @(
        (New-Object System.Drawing.PointF(36, 6)),
        (New-Object System.Drawing.PointF(16, 32)),
        (New-Object System.Drawing.PointF(30, 32)),
        (New-Object System.Drawing.PointF(24, 58)),
        (New-Object System.Drawing.PointF(48, 28)),
        (New-Object System.Drawing.PointF(34, 28))
    )
    $g.FillPolygon($brush, $boltPts)

    # Circuit orbit dot
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $g.FillEllipse($whiteBrush, 48, 12, 6, 6)
    $g.FillEllipse($whiteBrush, 12, 48, 6, 6)

    $brush.Dispose()
    $whiteBrush.Dispose()
}

# 4. m3_loot.png - Modern Gem / Diamond Loot Advisor
New-M3Icon "m3_loot.png" {
    param($g, $size)
    $cyan = [System.Drawing.Color]::FromArgb(255, 0, 229, 255)
    $pen = New-Object System.Drawing.Pen($cyan, 3.5)
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

    # Diamond crown & base
    $topPts = @(
        (New-Object System.Drawing.PointF(18, 20)),
        (New-Object System.Drawing.PointF(46, 20)),
        (New-Object System.Drawing.PointF(56, 32)),
        (New-Object System.Drawing.PointF(32, 56)),
        (New-Object System.Drawing.PointF(8, 32))
    )
    $g.DrawPolygon($pen, $topPts)

    # Facet lines
    $g.DrawLine($pen, 8, 32, 56, 32)
    $g.DrawLine($pen, 26, 20, 22, 32)
    $g.DrawLine($pen, 38, 20, 42, 32)
    $g.DrawLine($pen, 22, 32, 32, 56)
    $g.DrawLine($pen, 42, 32, 32, 56)

    $pen.Dispose()
}

# 5. m3_performance.png - Modern Speedometer / Turbo Gauge
New-M3Icon "m3_performance.png" {
    param($g, $size)
    $cyan = [System.Drawing.Color]::FromArgb(255, 0, 229, 255)
    $pen = New-Object System.Drawing.Pen($cyan, 3.5)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    # Gauge arc (from 140 to 40 degrees)
    $g.DrawArc($pen, 10, 10, 44, 44, 135, 270)

    # Gauge needle pointing high right
    $needlePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 80, 80), 3.5)
    $needlePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($needlePen, 32, 32, 48, 20)

    # Center pivot
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $g.FillEllipse($brush, 28, 28, 8, 8)

    $pen.Dispose()
    $needlePen.Dispose()
    $brush.Dispose()
}

# 6. m3_compatibility.png - Modern Interlocking Handshake / Linked Nodes
New-M3Icon "m3_compatibility.png" {
    param($g, $size)
    $cyan = [System.Drawing.Color]::FromArgb(255, 0, 229, 255)
    $purple = [System.Drawing.Color]::FromArgb(255, 199, 191, 255)

    $penCyan = New-Object System.Drawing.Pen($cyan, 3.5)
    $penPurple = New-Object System.Drawing.Pen($purple, 3.5)

    # Left ring / shield
    $g.DrawEllipse($penCyan, 10, 18, 28, 28)
    # Right ring / shield (overlapping)
    $g.DrawEllipse($penPurple, 26, 18, 28, 28)

    # Core link sparkle
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $g.FillEllipse($brush, 30, 29, 6, 6)

    $penCyan.Dispose()
    $penPurple.Dispose()
    $brush.Dispose()
}

# 7. m3_wizard.png - Modern Star Magic Wand
New-M3Icon "m3_wizard.png" {
    param($g, $size)
    $cyan = [System.Drawing.Color]::FromArgb(255, 0, 229, 255)
    $pen = New-Object System.Drawing.Pen($cyan, 3.5)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    # Wand handle
    $g.DrawLine($pen, 12, 52, 36, 28)

    # Star at top right
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $starPts = @(
        (New-Object System.Drawing.PointF(44, 8)),
        (New-Object System.Drawing.PointF(47, 18)),
        (New-Object System.Drawing.PointF(56, 20)),
        (New-Object System.Drawing.PointF(48, 26)),
        (New-Object System.Drawing.PointF(50, 36)),
        (New-Object System.Drawing.PointF(42, 30)),
        (New-Object System.Drawing.PointF(34, 34)),
        (New-Object System.Drawing.PointF(37, 25)),
        (New-Object System.Drawing.PointF(30, 18)),
        (New-Object System.Drawing.PointF(40, 18))
    )
    $g.FillPolygon($whiteBrush, $starPts)

    $pen.Dispose()
    $whiteBrush.Dispose()
}

# 8. m3_pill_active.png - 9-Slice Rounded Pill Texture for M3 Active Tab
New-M3Icon "m3_pill_active.png" {
    param($g, $size)
    # High-quality 64x64 rounded capsule texture
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0, 79, 81))
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 0, 229, 255), 2.0)

    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $rect = New-Object System.Drawing.Rectangle(2, 2, 60, 60)
    $r = 18
    $d = $r * 2
    $path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
    $path.AddArc($rect.Right - $d, $rect.Y, $d, $d, 270, 90)
    $path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
    $path.AddArc($rect.X, $rect.Bottom - $d, $d, $d, 90, 90)
    $path.CloseFigure()

    $g.FillPath($brush, $path)
    $g.DrawPath($pen, $path)

    $brush.Dispose()
    $pen.Dispose()
    $path.Dispose()
}

# 9. m3_close.png - Modern Minimalist Close X
New-M3Icon "m3_close.png" {
    param($g, $size)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(230, 255, 255, 255), 3.5)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    $g.DrawLine($pen, 18, 18, 46, 46)
    $g.DrawLine($pen, 46, 18, 18, 46)
    $pen.Dispose()
}

# 10. m3_sound_on.png - Modern Speaker with Audio Waves
New-M3Icon "m3_sound_on.png" {
    param($g, $size)
    $cyan = [System.Drawing.Color]::FromArgb(255, 0, 229, 255)
    $brush = New-Object System.Drawing.SolidBrush($cyan)
    $pen = New-Object System.Drawing.Pen($cyan, 3.5)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    # Speaker horn
    $pts = @(
        (New-Object System.Drawing.PointF(10, 22)),
        (New-Object System.Drawing.PointF(20, 22)),
        (New-Object System.Drawing.PointF(32, 12)),
        (New-Object System.Drawing.PointF(32, 52)),
        (New-Object System.Drawing.PointF(20, 42)),
        (New-Object System.Drawing.PointF(10, 42))
    )
    $g.FillPolygon($brush, $pts)

    # Sound waves
    $g.DrawArc($pen, 26, 20, 22, 24, -50, 100)
    $g.DrawArc($pen, 34, 14, 22, 36, -55, 110)

    $brush.Dispose()
    $pen.Dispose()
}

# 11. m3_sound_off.png - Modern Speaker Muted with Slash
New-M3Icon "m3_sound_off.png" {
    param($g, $size)
    $muted = [System.Drawing.Color]::FromArgb(255, 160, 163, 175)
    $red = [System.Drawing.Color]::FromArgb(255, 255, 100, 100)
    $brush = New-Object System.Drawing.SolidBrush($muted)
    $penSlash = New-Object System.Drawing.Pen($red, 3.5)
    $penSlash.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $penSlash.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    # Speaker horn
    $pts = @(
        (New-Object System.Drawing.PointF(10, 22)),
        (New-Object System.Drawing.PointF(20, 22)),
        (New-Object System.Drawing.PointF(32, 12)),
        (New-Object System.Drawing.PointF(32, 52)),
        (New-Object System.Drawing.PointF(20, 42)),
        (New-Object System.Drawing.PointF(10, 42))
    )
    $g.FillPolygon($brush, $pts)

    # Slash across
    $g.DrawLine($penSlash, 14, 14, 50, 50)

    $brush.Dispose()
    $penSlash.Dispose()
}

# 12. m3_check.png - Crisp Modern Checkmark for M3 Checkboxes
New-M3Icon "m3_check.png" {
    param($g, $size)
    $white = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
    $pen = New-Object System.Drawing.Pen($white, 8.5)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

    $pts = @(
        (New-Object System.Drawing.PointF(14, 34)),
        (New-Object System.Drawing.PointF(27, 47)),
        (New-Object System.Drawing.PointF(51, 17))
    )
    $g.DrawLines($pen, $pts)
    $pen.Dispose()
}

Write-Host "All modern M3 icons generated successfully!"
