# Packaging script for CurseForge / WoW AddOn
param (
    [string]$OutputDir = "$PSScriptRoot\release"
)

$ErrorActionPreference = "Stop"

$addonName = "DistractionQoL"
$sourceDir = Join-Path $PSScriptRoot $addonName

if (-not (Test-Path $sourceDir)) {
    Write-Error "Addon directory not found: $sourceDir"
    exit 1
}

# Create output directory if it does not exist
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$zipPath = Join-Path $OutputDir "$addonName.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Write-Host "Packaging $addonName for CurseForge..." -ForegroundColor Cyan

# Compress clean DistractionQoL addon folder
Compress-Archive -Path $sourceDir -DestinationPath $zipPath -CompressionLevel Optimal

Write-Host "Packaging successful!" -ForegroundColor Green
Write-Host "Archive generated: $zipPath" -ForegroundColor Yellow
