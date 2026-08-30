param(
    [string]$GodotPath = "",
    [switch]$Fast,
    [ValidateRange(1, 20)]
    [int]$RetainedLogRuns = 3
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
	"test_mission_rules.gd",
	"test_hunt_timing_rules.gd",
	"test_hunt_fuel.gd",
	"test_mission_pacing.gd",
	"test_long_horizon_economy.gd",
	"test_rift_calendar_economy.gd",
	"test_rift_year_one_chronology.gd",
	"test_year_one_content.gd",
	"test_launch_content_coverage.gd",
	"test_planet_content_packs.gd",
	"test_backend_content_manifest.gd",
	"test_content_indices.gd",
	"test_mission_network_compatibility.gd",
	"test_performance_hotpaths.gd",
    "test_attributes.gd",
	"test_attribute_packages.gd",
    "test_classes.gd",
	"test_tactical_profiles.gd",
	"test_onboarding.gd",
	"test_account_boundary.gd",
	"test_backend_protocol.gd",
	"test_remote_economy_rules.gd",
	"test_backend_deployment_rules.gd",
	"test_nakama_backend_adapter.gd",
	"test_remote_session_coordinator.gd",
	"test_remote_command_dispatcher.gd",
	"test_remote_runtime_boundary.gd",
	"test_profile_sync_rules.gd",
	"test_local_save_cutover_archive.gd",
	"test_agency_rules.gd",
	"test_remote_agency_dispatcher.gd",
	"test_simulation_builds.gd",
    "test_balance_guards.gd",
	"test_late_approach_cohorts.gd",
    "test_flow.gd",
    "test_ui.gd",
    "test_ui_factory.gd",
    "test_reference_placeholders.gd",
	"test_visual_asset_catalog.gd",
    "test_environment_backdrop.gd",
    "test_focus_navigation.gd",
    "test_motion_preferences.gd",
    "test_text_resilience.gd",
	"test_lifecycle_timers.gd",
	"test_android_feedback.gd",
    "test_arsenal_view.gd",
	"test_market.gd",
	"test_collection_rules.gd",
	"test_daily_objectives.gd",
	"test_weekly_operations.gd",
	"test_weekly_operations_ui.gd",
	"test_transport.gd",
	"test_challenges.gd",
	"test_translation_complete.gd",
    "test_reward_view.gd",
    "test_career_view.gd",
    "test_persistence.gd",
    "test_save_failures.gd",
    "test_save_backups.gd",
    "test_corrupt_save_recovery.gd",
    "test_afk_persistence.gd",
    "test_clean_roundtrip.gd",
    "test_persistence_matrix.gd",
    "test_save_migrations.gd",
    "test_equipment_presentation.gd",
    "test_equipment_icon.gd",
	"test_equipment_slots.gd",
    "test_loadout_portrait.gd",
    "test_career_rules.gd",
    "test_career_persistence.gd",
    "test_contract_rules.gd",
    "test_audio.gd",
    "test_content.gd",
    "test_mobile.gd"
)

$SuiteStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$Profile = if ($Fast) { "fast" } else { "full" }
Write-Host "Crooked Galaxy $Profile checks using $GodotExe"
$GlobalClassCache = Join-Path $ProjectRoot ".godot\global_script_class_cache.cfg"
if (-not (Test-Path -LiteralPath $GlobalClassCache -PathType Leaf)) {
	Write-Host "`n[cold project import]"
	& $GodotExe --headless --editor --path $ProjectRoot --quit
	if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $GlobalClassCache -PathType Leaf)) {
		throw "Godot could not initialize the global script-class cache for a clean checkout."
	}
}
Write-Host "`n[repository hygiene]"
& (Join-Path $PSScriptRoot "check_repository_hygiene.ps1")
Write-Host "`n[documentation contracts]"
& (Join-Path $PSScriptRoot "check_documentation_contracts.ps1")
Write-Host "`n[reference boundaries]"
& (Join-Path $PSScriptRoot "check_reference_boundaries.ps1")
Write-Host "`n[backend workspace]"
& (Join-Path $PSScriptRoot "check_backend_workspace.ps1")
Write-Host "`n[Nakama Godot add-on]"
& (Join-Path $PSScriptRoot "check_nakama_addon.ps1")
foreach ($TestFile in $Tests) {
    Write-Host "`n[$TestFile]"
    $LogFile = Join-Path $LogRoot "$TestFile.log"
    $TestStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    & $GodotExe --headless --path $ProjectRoot --log-file $LogFile --script "res://tests/$TestFile"
    $TestStopwatch.Stop()
    if ($LASTEXITCODE -ne 0) {
        throw "$TestFile failed with exit code $LASTEXITCODE."
    }
    Write-Host ("[{0:N2}s]" -f $TestStopwatch.Elapsed.TotalSeconds)
}

Write-Host "`n[project boot]"
$BootLog = Join-Path $LogRoot "project_boot.log"
& $GodotExe --headless --path $ProjectRoot --log-file $BootLog --quit-after 2
if ($LASTEXITCODE -ne 0) {
    throw "Project boot failed with exit code $LASTEXITCODE."
}

$SuiteStopwatch.Stop()
if (Test-Path -LiteralPath $LogRoot) {
    $ResolvedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
    $ResolvedLogParent = [System.IO.Path]::GetFullPath((Split-Path -Parent $LogRoot)).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
    $ExpectedLogParent = Join-Path $ResolvedProjectRoot ".godot\test-logs"
    if ($ResolvedLogParent -ne [System.IO.Path]::GetFullPath($ExpectedLogParent).TrimEnd([System.IO.Path]::DirectorySeparatorChar)) {
        throw "Refusing to prune test logs outside the project log directory: $ResolvedLogParent"
    }
    # Only prune run directories created by this script. Focused/manual test
    # directories use descriptive names and may still be held open by Godot.
    $ManagedLogRuns = @(Get-ChildItem -LiteralPath $ResolvedLogParent -Directory | Where-Object {
        $_.Name -match '^[0-9a-fA-F]{32}$'
    })
    $OldLogRuns = @($ManagedLogRuns | Sort-Object LastWriteTimeUtc -Descending | Select-Object -Skip $RetainedLogRuns)
    foreach ($OldLogRun in $OldLogRuns) {
        $ResolvedOldLogRun = [System.IO.Path]::GetFullPath($OldLogRun.FullName)
        if (-not $ResolvedOldLogRun.StartsWith($ResolvedLogParent + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove an unexpected test-log path: $ResolvedOldLogRun"
        }
        Remove-Item -LiteralPath $ResolvedOldLogRun -Recurse -Force
    }
}
Write-Host ("`nPASS: all Crooked Galaxy {0} checks completed in {1:N2}s." -f $Profile, $SuiteStopwatch.Elapsed.TotalSeconds)
