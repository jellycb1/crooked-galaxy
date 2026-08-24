param(
    [string]$GodotPath = "C:\Tools\Godot\Godot_v4.7.1-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ApkPath = Join-Path $ProjectRoot "builds\android\CrookedGalaxy-Internal-References.apk"
$PackPath = Join-Path $ProjectRoot "builds\android\CrookedGalaxy-Internal-References.pck"
$InspectorRoot = Join-Path $ProjectRoot "tools\export_pack_inspector"
$StageRoot = Join-Path $ProjectRoot "internal_reference_assets"
$ReferenceRoot = Join-Path $ProjectRoot "References\Shakes and Fidget Assets\StreamingAssets"
$StageMap = @{
    "contracts.png.bin" = Join-Path $ReferenceRoot "tavern\tavern_back.png"
    "world.png.bin" = Join-Path $ReferenceRoot "town\bg_town_day.png"
    "workshop.png.bin" = Join-Path $ReferenceRoot "locations\bg_fort_0.png"
    "combat.png.bin" = Join-Path $ReferenceRoot "locations\location_battle_0.png"
}

New-Item -ItemType Directory -Path $StageRoot -Force | Out-Null
foreach ($StageName in $StageMap.Keys) {
    $SourcePath = $StageMap[$StageName]
    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Missing local reference placeholder: $SourcePath"
    }
    Copy-Item -LiteralPath $SourcePath -Destination (Join-Path $StageRoot $StageName) -Force
}

& $GodotPath --headless --path $ProjectRoot --log-file "builds/android/internal_apk_export.log" --export-debug "Android Internal References" $ApkPath
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $ApkPath)) {
    throw "Internal Android APK export failed."
}

& $GodotPath --headless --path $ProjectRoot --log-file "builds/android/internal_pack_export.log" --export-pack "Android Internal References" $PackPath
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $PackPath)) {
    throw "Internal reference pack export failed."
}

& $GodotPath --headless --path $InspectorRoot --log-file $PackPath.Replace(".pck", ".inspect.log") --script res://inspect_pack.gd -- $PackPath internal-references
if ($LASTEXITCODE -ne 0) {
    throw "Internal Android reference boundary inspection failed."
}

$SizeMb = [math]::Round((Get-Item -LiteralPath $ApkPath).Length / 1MB, 2)
Write-Host "PASS: internal Android APK exported with documented placeholders ($SizeMb MB)."
