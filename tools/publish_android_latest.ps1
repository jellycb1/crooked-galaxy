param(
    [string]$GodotPath = "",
    [string]$Repository = "jellycb1/crooked-galaxy"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ExportScript = Join-Path $PSScriptRoot "check_android_export.ps1"
$OutputApk = Join-Path $ProjectRoot "builds\android\CrookedGalaxy.apk"
$DownloadUrl = "https://github.com/$Repository/releases/download/latest/CrookedGalaxy.apk"

& $ExportScript -GodotPath $GodotPath
if ($LASTEXITCODE -ne 0) {
    throw "Android export validation failed with exit code $LASTEXITCODE."
}

& gh auth status --hostname github.com
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is not authenticated. Run gh auth login first."
}

$Commit = (& git -C $ProjectRoot rev-parse --short HEAD).Trim()
$ProjectText = Get-Content -LiteralPath (Join-Path $ProjectRoot "project.godot") -Raw
$VersionMatch = [regex]::Match($ProjectText, 'config/version="([^"]+)"')
if (-not $VersionMatch.Success) {
    throw "Could not resolve config/version from project.godot."
}
$Version = $VersionMatch.Groups[1].Value
$Notes = "Crooked Galaxy $Version Android test build from commit $Commit. ARM64, update-compatible debug signature for direct testing."

& gh release view latest --repo $Repository *> $null
if ($LASTEXITCODE -eq 0) {
    & gh release edit latest --repo $Repository --title "Latest Android build" --notes $Notes
    if ($LASTEXITCODE -ne 0) {
        throw "Could not update the latest release metadata."
    }
    & gh release upload latest "$OutputApk#CrookedGalaxy.apk" --repo $Repository --clobber
} else {
    & gh release create latest "$OutputApk#CrookedGalaxy.apk" --repo $Repository --title "Latest Android build" --notes $Notes
}
if ($LASTEXITCODE -ne 0) {
    throw "Could not publish CrookedGalaxy.apk."
}

Write-Host "PASS: Android APK published at $DownloadUrl"
