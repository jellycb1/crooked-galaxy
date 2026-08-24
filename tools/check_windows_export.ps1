param(
    [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
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
$BuildRoot = Join-Path $ProjectRoot "builds\windows"
$OutputExe = Join-Path $BuildRoot "CrookedGalaxy.exe"
$OutputPck = Join-Path $BuildRoot "CrookedGalaxy.pck"
$LogRoot = Join-Path $ProjectRoot ".godot\export-logs"
New-Item -ItemType Directory -Path $BuildRoot -Force | Out-Null
New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null

& $GodotExe --headless --path $ProjectRoot --export-release "Windows Desktop" $OutputExe --log-file (Join-Path $LogRoot "windows_export.log")
if ($LASTEXITCODE -ne 0) {
    throw "Windows release export failed with exit code $LASTEXITCODE."
}
if (-not (Test-Path -LiteralPath $OutputExe) -or -not (Test-Path -LiteralPath $OutputPck)) {
    throw "Windows export did not produce both CrookedGalaxy.exe and CrookedGalaxy.pck."
}

& $OutputExe --headless --quit-after 2 --log-file (Join-Path $LogRoot "windows_smoke.log") -- --smoke-test
if ($LASTEXITCODE -ne 0) {
    throw "Exported Windows build failed its isolated smoke boot with exit code $LASTEXITCODE."
}

$ExeSizeMb = (Get-Item -LiteralPath $OutputExe).Length / 1MB
$PckSizeMb = (Get-Item -LiteralPath $OutputPck).Length / 1MB
Write-Host ("PASS: Windows release exported and smoke-booted ({0:N2} MB exe + {1:N2} MB pck)." -f $ExeSizeMb, $PckSizeMb)
