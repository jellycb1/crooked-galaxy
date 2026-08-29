param(
    [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$EnvironmentPath = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path -LiteralPath $EnvironmentPath -PathType Leaf)) {
    throw "Run backend/prepare_local_env.ps1 first."
}
$Environment = @{}
foreach ($Line in Get-Content -LiteralPath $EnvironmentPath) {
    if ($Line -match '^([^#=]+)=(.+)$') {
        $Environment[$Matches[1]] = $Matches[2]
    }
}
$ClientKey = [string]$Environment.CG_NAKAMA_SERVER_KEY
if ([string]::IsNullOrWhiteSpace($ClientKey)) {
    throw "Local Nakama client key is missing."
}

$GodotCandidates = @(@(
    $GodotPath,
    "C:\Tools\Godot\Godot_v4.7.1-stable_win64_console.exe",
    (Get-Command godot -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
    (Get-Command godot4 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) })
if ($GodotCandidates.Count -eq 0) {
    throw "Godot not found. Use -GodotPath with the installed console executable."
}

$PreviousValue = [Environment]::GetEnvironmentVariable("CG_LOCAL_NAKAMA_SERVER_KEY", "Process")
try {
    [Environment]::SetEnvironmentVariable("CG_LOCAL_NAKAMA_SERVER_KEY", $ClientKey, "Process")
    $LogPath = Join-Path $ProjectRoot ".godot\nakama-local-integration.log"
    & $GodotCandidates[0] --headless --path $ProjectRoot --log-file $LogPath --script "res://tests/test_nakama_local_integration.gd"
    if ($LASTEXITCODE -ne 0) {
        throw "Godot-to-Nakama integration failed with exit code $LASTEXITCODE."
    }
} finally {
    [Environment]::SetEnvironmentVariable("CG_LOCAL_NAKAMA_SERVER_KEY", $PreviousValue, "Process")
}
Write-Host "PASS: Godot client integration completed without persisting or printing the local client key."
