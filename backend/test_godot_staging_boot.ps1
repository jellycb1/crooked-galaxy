param(
    [string]$GodotPath = "",
    [string]$SshTarget = "cgdeploy@2.29.2.190",
    [string]$StagingHost = "staging-api.crookedgalaxy.com",
    [string]$DeviceId = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($DeviceId)) {
    $DeviceId = "cg-staging-boot-$([Guid]::NewGuid().ToString('N'))"
}
if ($StagingHost -notmatch '^[a-z0-9.-]+$' -or $DeviceId -notmatch '^[a-z0-9_-]{16,128}$') {
    throw "Unsafe staging host or test device identifier."
}
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$GodotCandidates = @(@(
    $GodotPath,
    "C:\Tools\Godot\Godot_v4.7.1-stable_win64_console.exe",
    (Get-Command godot -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
    (Get-Command godot4 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) })
if ($GodotCandidates.Count -eq 0) { throw "Godot console executable not found." }

$ClientKey = (& ssh $SshTarget "sed -n 's/^CG_NAKAMA_SERVER_KEY=//p' /opt/crooked-galaxy/backend/.env.staging").Trim()
if ($LASTEXITCODE -ne 0 -or $ClientKey.Length -lt 16) {
    throw "Could not retrieve the staging client key through the protected operator path."
}

$PreviousKey = [Environment]::GetEnvironmentVariable("CG_STAGING_NAKAMA_SERVER_KEY", "Process")
$PreviousHost = [Environment]::GetEnvironmentVariable("CG_STAGING_NAKAMA_HOST", "Process")
$PreviousDevice = [Environment]::GetEnvironmentVariable("CG_STAGING_DEVICE_ID", "Process")
try {
    [Environment]::SetEnvironmentVariable("CG_STAGING_NAKAMA_SERVER_KEY", $ClientKey, "Process")
    [Environment]::SetEnvironmentVariable("CG_STAGING_NAKAMA_HOST", $StagingHost, "Process")
    [Environment]::SetEnvironmentVariable("CG_STAGING_DEVICE_ID", $DeviceId, "Process")
    $LogPath = Join-Path $ProjectRoot ".godot\nakama-staging-boot.log"
    & $GodotCandidates[0] --headless --path $ProjectRoot --log-file $LogPath -- --smoke-test --staging-boot-probe
    if ($LASTEXITCODE -ne 0) { throw "Normal-boot staging probe failed with exit code $LASTEXITCODE." }
} finally {
    [Environment]::SetEnvironmentVariable("CG_STAGING_NAKAMA_SERVER_KEY", $PreviousKey, "Process")
    [Environment]::SetEnvironmentVariable("CG_STAGING_NAKAMA_HOST", $PreviousHost, "Process")
    [Environment]::SetEnvironmentVariable("CG_STAGING_DEVICE_ID", $PreviousDevice, "Process")
    $ClientKey = $null
}
Write-Host "PASS: normal Godot boot completed the public TLS, archival-cutover, cache, and reconnect probe without persisting or printing the client key."
