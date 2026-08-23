param(
    [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$GodotCandidates = @(@(
    $GodotPath,
    "C:\Tools\Godot\Godot_v4.7.1-stable_win64_console.exe",
    (Get-Command godot -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
    (Get-Command godot4 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) })

if ($GodotCandidates.Count -eq 0) {
    throw "Godot not found. Use -GodotPath with the installed console executable."
}

$GodotExe = $GodotCandidates[0]
$Tests = @(
    "test_core.gd",
    "test_flow.gd",
    "test_ui.gd",
    "test_persistence.gd",
    "test_save_migrations.gd",
    "test_equipment_presentation.gd",
    "test_career_rules.gd",
    "test_contract_rules.gd",
    "test_audio.gd",
    "test_content.gd",
    "test_mobile.gd"
)

Write-Host "Crooked Galaxy checks using $GodotExe"
foreach ($TestFile in $Tests) {
    Write-Host "`n[$TestFile]"
    & $GodotExe --headless --path $ProjectRoot --script "res://tests/$TestFile"
    if ($LASTEXITCODE -ne 0) {
        throw "$TestFile failed with exit code $LASTEXITCODE."
    }
}

Write-Host "`n[project boot]"
& $GodotExe --headless --path $ProjectRoot --quit-after 2
if ($LASTEXITCODE -ne 0) {
    throw "Project boot failed with exit code $LASTEXITCODE."
}

Write-Host "`nPASS: all Crooked Galaxy checks completed."
