$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$BackendRoot = $PSScriptRoot
$EnvironmentPath = Join-Path $BackendRoot ".env"
if (-not (Test-Path -LiteralPath $EnvironmentPath -PathType Leaf)) {
    throw "Run backend/prepare_local_env.ps1 first."
}

$Environment = @{}
foreach ($Line in Get-Content -LiteralPath $EnvironmentPath) {
    if ($Line -match '^([^#=]+)=(.+)$') {
        $Environment[$Matches[1]] = $Matches[2]
    }
}
$ServerKey = [string]$Environment.CG_NAKAMA_SERVER_KEY
if ([string]::IsNullOrWhiteSpace($ServerKey)) {
    throw "Local Nakama server key is missing."
}

$Health = Invoke-WebRequest -Method Get -Uri "http://127.0.0.1:7350/healthcheck"
if ($Health.StatusCode -ne 200) {
    throw "Nakama health endpoint did not return HTTP 200."
}

$DeviceId = "cg-local-smoke-00000001"
$BasicBytes = [Text.Encoding]::UTF8.GetBytes("${ServerKey}:")
$Basic = [Convert]::ToBase64String($BasicBytes)
$AuthHeaders = @{ Authorization = "Basic $Basic" }
$AuthUri = "http://127.0.0.1:7350/v2/account/authenticate/device?create=true&username=cg_local_smoke"
$Session = Invoke-RestMethod -Method Post -Uri $AuthUri -Headers $AuthHeaders -ContentType "application/json" -Body (@{ id = $DeviceId } | ConvertTo-Json -Compress)
if ([string]::IsNullOrWhiteSpace([string]$Session.token)) {
    throw "Nakama device authentication returned no session token."
}

$RpcHeaders = @{ Authorization = "Bearer $($Session.token)" }
$AnonymousRejected = $false
try {
    Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:7350/v2/rpc/cg_clock" -ContentType "application/json" -Body '"{}"' | Out-Null
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        $AnonymousRejected = $true
    } else {
        throw
    }
}
if (-not $AnonymousRejected) {
    throw "Clock RPC accepted a request without an authenticated session."
}
$Before = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$Rpc = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:7350/v2/rpc/cg_clock" -Headers $RpcHeaders -ContentType "application/json" -Body '"{}"'
$After = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$Clock = [string]$Rpc.payload | ConvertFrom-Json
if ([int]$Clock.api_version -ne 1 -or [string]$Clock.authority -ne "server" -or [string]$Clock.shard_id -ne "international_1") {
    throw "Clock RPC returned an invalid Crooked Galaxy protocol envelope."
}
if ([int64]$Clock.server_unix_ms -lt $Before -or [int64]$Clock.server_unix_ms -gt $After) {
    throw "Clock RPC timestamp falls outside the observed UTC request window."
}

Write-Host "PASS: local Nakama health, authenticated session, and authoritative Crooked Galaxy UTC RPC are valid."
