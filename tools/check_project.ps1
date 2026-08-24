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
$RunId = [Guid]::NewGuid().ToString("N")
$LogRoot = Join-Path $ProjectRoot ".godot\test-logs\$RunId"
New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null
$Tests = @(
    "test_core.gd",
    "test_balance_guards.gd",
    "test_flow.gd",
    "test_ui.gd",
    "test_ui_factory.gd",
    "test_focus_navigation.gd",
    "test_motion_preferences.gd",
    "test_text_resilience.gd",
    "test_lifecycle_timers.gd",
    "test_arsenal_view.gd",
    "test_reward_view.gd",
    "test_career_view.gd",
    "test_persistence.gd",
    "test_save_failures.gd",
    "test_save_backups.gd",
    "test_corrupt_save_recovery.gd",
    "test_afk_persistence.gd",
    "test_clean_roundtrip.gd",
    "test_save_migrations.gd",
    "test_equipment_presentation.gd",
    "test_career_rules.gd",
    "test_career_persistence.gd",
    "test_contract_rules.gd",
    "test_audio.gd",
    "test_content.gd",
    "test_mobile.gd"
)

Write-Host "Crooked Galaxy checks using $GodotExe"
foreach ($TestFile in $Tests) {
    Write-Host "`n[$TestFile]"
    $LogFile = Join-Path $LogRoot "$TestFile.log"
    & $GodotExe --headless --path $ProjectRoot --log-file $LogFile --script "res://tests/$TestFile"
    if ($LASTEXITCODE -ne 0) {
        throw "$TestFile failed with exit code $LASTEXITCODE."
    }
}

Write-Host "`n[project boot]"
$BootLog = Join-Path $LogRoot "project_boot.log"
& $GodotExe --headless --path $ProjectRoot --log-file $BootLog --quit-after 2
if ($LASTEXITCODE -ne 0) {
    throw "Project boot failed with exit code $LASTEXITCODE."
}

Write-Host "`nPASS: all Crooked Galaxy checks completed."
