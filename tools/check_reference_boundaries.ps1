$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ExpectedTrackedReference = "References/.gdignore"
$TrackedReference = @(& git -C $ProjectRoot ls-files -- References)
if ($LASTEXITCODE -ne 0) {
    throw "Could not inspect tracked reference files."
}
if ($TrackedReference.Count -ne 1 -or $TrackedReference[0] -ne $ExpectedTrackedReference) {
    throw "Only References/.gdignore may be tracked; found: $($TrackedReference -join ', ')"
}

$ReferenceIgnore = Join-Path $ProjectRoot "References\.gdignore"
if (-not (Test-Path -LiteralPath $ReferenceIgnore)) {
    throw "References/.gdignore is required."
}

$PresetText = Get-Content -LiteralPath (Join-Path $ProjectRoot "export_presets.cfg") -Raw
$ExcludedPresetCount = [regex]::Matches($PresetText, 'exclude_filter="[^"]*References/\*[^"]*"').Count
if ($ExcludedPresetCount -lt 2) {
    throw "Windows and Android export presets must exclude raw References/*."
}
if ($PresetText.Contains('name="Android Internal References"')) {
    throw "The obsolete second Android reference profile must not return."
}
if (-not $PresetText.Contains('name="Android APK"') -or
    $PresetText.Contains('custom_features="reference_placeholders"') -or
    $PresetText.Contains('include_filter="internal_reference_assets/*.png.bin"')) {
    throw "The Android APK must not include staged reference placeholders."
}

$ApprovedReferencePathFiles = @("tools/export_pack_inspector/inspect_pack.gd")
$TrackedRuntimeFiles = @(& git -C $ProjectRoot ls-files -- "*.gd" "*.tscn" "*.tres" "project.godot")
foreach ($RelativePath in $TrackedRuntimeFiles) {
    if ($ApprovedReferencePathFiles -contains $RelativePath) {
        continue
    }
    $AbsolutePath = Join-Path $ProjectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $AbsolutePath)) {
        continue
    }
    if ((Get-Content -LiteralPath $AbsolutePath -Raw).Contains("res://References/")) {
        throw "Direct reference-asset path outside the approved loader: $RelativePath"
    }
}

Write-Host "PASS: raw references remain Git-local and are excluded from every runtime export."
