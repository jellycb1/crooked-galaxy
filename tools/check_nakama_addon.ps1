$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$AddonRoot = Join-Path $ProjectRoot "addons\com.heroiclabs.nakama"
$VendorPath = Join-Path $AddonRoot "VENDOR.json"
$LockPath = Join-Path $ProjectRoot "backend\stack-lock.json"
if (-not (Test-Path -LiteralPath $VendorPath -PathType Leaf) -or -not (Test-Path -LiteralPath $LockPath -PathType Leaf)) {
    throw "Pinned Nakama add-on manifest or backend stack lock is missing."
}
$Vendor = Get-Content -LiteralPath $VendorPath -Raw | ConvertFrom-Json
$Lock = Get-Content -LiteralPath $LockPath -Raw | ConvertFrom-Json
if ([string]$Vendor.version -ne [string]$Lock.nakama_godot_client -or
    [string]$Vendor.tag -ne "v$($Lock.nakama_godot_client)" -or
    [string]$Vendor.archive_sha256 -ne [string]$Lock.nakama_godot_archive_sha256 -or
    [string]$Vendor.commit -ne "14b7f7078a9822c15b0424624e4c883c87730cee" -or
    [int]$Vendor.archive_bytes -ne 90474 -or
    [string]$Vendor.source -ne "https://github.com/heroiclabs/nakama-godot/releases/tag/v$($Lock.nakama_godot_client)" -or
    [string]$Vendor.license -ne "Apache-2.0") {
    throw "Vendored Nakama add-on provenance diverged from the reviewed stack lock."
}
foreach ($Property in $Vendor.core_file_sha256.PSObject.Properties) {
    $RelativePath = [string]$Property.Name
    $ExpectedHash = ([string]$Property.Value).ToLowerInvariant()
    $FilePath = Join-Path $AddonRoot ($RelativePath -replace '/', '\')
    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        throw "Vendored Nakama core file is missing: $RelativePath"
    }
    $ActualHash = (Get-FileHash -LiteralPath $FilePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($ActualHash -ne $ExpectedHash) {
        throw "Vendored Nakama core file was modified: $RelativePath"
    }
}
$ProjectText = Get-Content -LiteralPath (Join-Path $ProjectRoot "project.godot") -Raw
if (-not $ProjectText.Contains('Nakama="*res://addons/com.heroiclabs.nakama/Nakama.gd"')) {
    throw "Official Nakama singleton is not registered as the reviewed autoload."
}
$AdapterText = Get-Content -LiteralPath (Join-Path $ProjectRoot "scripts\nakama_backend_adapter.gd") -Raw
if ($AdapterText.Contains("OS.get_unique_id") -or $AdapterText.Contains("defaultkey") -or $AdapterText.Contains("CG_NAKAMA_SERVER_KEY")) {
    throw "Nakama adapter contains a forbidden device identity or embedded local client key."
}
Write-Host "PASS: official Nakama Godot add-on provenance, core hashes, autoload, and adapter boundary are valid."
