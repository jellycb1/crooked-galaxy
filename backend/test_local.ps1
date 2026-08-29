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

$RunId = [Guid]::NewGuid().ToString("N")
$DeviceId = "cg-local-smoke-$RunId"
$BasicBytes = [Text.Encoding]::UTF8.GetBytes("${ServerKey}:")
$Basic = [Convert]::ToBase64String($BasicBytes)
$AuthHeaders = @{ Authorization = "Basic $Basic" }
$Username = "cg_$($RunId.Substring(0, 20))"
$AuthUri = "http://127.0.0.1:7350/v2/account/authenticate/device?create=true&username=$Username"
$Session = Invoke-RestMethod -Method Post -Uri $AuthUri -Headers $AuthHeaders -ContentType "application/json" -Body (@{ id = $DeviceId } | ConvertTo-Json -Compress)
if ([string]::IsNullOrWhiteSpace([string]$Session.token)) {
    throw "Nakama device authentication returned no session token."
}

$RpcHeaders = @{ Authorization = "Bearer $($Session.token)" }
function Invoke-CgRpc {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][hashtable]$Payload
    )
    $InnerJson = $Payload | ConvertTo-Json -Depth 10 -Compress
    $OuterJson = ConvertTo-Json -InputObject $InnerJson -Compress
    $Envelope = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:7350/v2/rpc/$Name" -Headers $RpcHeaders -ContentType "application/json" -Body $OuterJson
    return [string]$Envelope.payload | ConvertFrom-Json
}
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

$Missing = Invoke-CgRpc -Name "cg_character_get" -Payload @{}
if ($Missing.exists -ne $false -or [string]::IsNullOrWhiteSpace([string]$Missing.account_id)) {
    throw "Fresh account did not return the canonical missing-character result."
}
$AccountId = [string]$Missing.account_id
$Appearance = @{ palette = "native"; eyes = "standard"; feature = "classic"; marking = "clean" }
$CreatePayload = @{
    idempotency_key = "create-$RunId"
    hunter_name = "Nova Trace"
    class_id = "orbit_gunslinger"
    species_id = "terran"
    appearance = $Appearance
}
$Created = Invoke-CgRpc -Name "cg_character_create" -Payload $CreatePayload
if ($Created.created -ne $true -or [int]$Created.revision -ne 0 -or [int]$Created.profile.level -ne 1 -or [int]$Created.profile.credits -ne 25) {
    throw "Authoritative character creation did not apply the fixed launch baseline."
}
if ([string]$Created.character_id -ne $AccountId -or [string]$Created.profile.class_id -ne "orbit_gunslinger") {
    throw "Created character is not owned by the authenticated account."
}
$CreateReplay = Invoke-CgRpc -Name "cg_character_create" -Payload $CreatePayload
if ($CreateReplay.idempotent_replay -ne $true -or [int]$CreateReplay.revision -ne 0) {
    throw "Character creation did not replay idempotently."
}
$SessionSummary = Invoke-CgRpc -Name "cg_session" -Payload @{}
if ([string]$SessionSummary.account_id -ne $AccountId -or [string]$SessionSummary.active_character_id -ne $AccountId -or [string]$SessionSummary.session_state -ne "authenticated") {
    throw "Authenticated session summary did not bind the owned active character."
}
if (@($SessionSummary.owned_character_ids).Count -ne 1 -or [string]$SessionSummary.owned_character_ids[0] -ne $AccountId) {
    throw "Session summary returned an invalid owned-character set."
}

$CommandId = "commit-$RunId"
$CommitPayload = @{
    api_version = 1
    command_id = $CommandId
    idempotency_key = "receipt-$RunId"
    operation = "profile_commit"
    session_id = $AccountId
    shard_id = "international_1"
    character_id = $AccountId
    expected_revision = 0
    payload = @{ hunter_name = "Nova Vector"; appearance = @{ palette = "cool"; eyes = "narrow"; feature = "bold"; marking = "stripe" } }
}
$Accepted = Invoke-CgRpc -Name "cg_character_commit" -Payload $CommitPayload
if ([string]$Accepted.status -ne "accepted" -or [int]$Accepted.server_revision -ne 1 -or [int]$Accepted.snapshot.profile.credits -ne 25) {
    throw "Valid cosmetic profile commit was not accepted without altering server-owned progression."
}
$Duplicate = Invoke-CgRpc -Name "cg_character_commit" -Payload $CommitPayload
if ([string]$Duplicate.status -ne "duplicate" -or [int]$Duplicate.server_revision -ne 1) {
    throw "Accepted profile command did not replay from its idempotency receipt."
}
$StalePayload = $CommitPayload.Clone()
$StalePayload.command_id = "stale-$RunId"
$StalePayload.idempotency_key = "stale-receipt-$RunId"
$Stale = Invoke-CgRpc -Name "cg_character_commit" -Payload $StalePayload
if ([string]$Stale.status -ne "conflict" -or [int]$Stale.server_revision -ne 1) {
    throw "Stale profile revision was not rejected as an explicit conflict."
}
$ForgedPayload = $CommitPayload.Clone()
$ForgedPayload.command_id = "forged-$RunId"
$ForgedPayload.idempotency_key = "forged-receipt-$RunId"
$ForgedPayload.expected_revision = 1
$ForgedPayload.payload = @{ hunter_name = "Nova Vector"; appearance = $Appearance; credits = 999999 }
$Forged = Invoke-CgRpc -Name "cg_character_commit" -Payload $ForgedPayload
if ([string]$Forged.status -ne "rejected" -or [string]$Forged.reason_code -ne "invalid_profile_change") {
    throw "Client-authored currency mutation was not rejected."
}
$Final = Invoke-CgRpc -Name "cg_character_get" -Payload @{}
if ([int]$Final.revision -ne 1 -or [int]$Final.profile.credits -ne 25 -or [string]$Final.profile.hunter_name -ne "Nova Vector") {
    throw "Final authoritative snapshot changed after rejected or conflicting commands."
}

# Exercise real concurrent writes against a second fresh account. Both callers
# use the exact same command identity, as a mobile retry may after a timeout.
$RaceDeviceId = "cg-race-smoke-$RunId"
$RaceUsername = "race_$($RunId.Substring(0, 20))"
$RaceAuthUri = "http://127.0.0.1:7350/v2/account/authenticate/device?create=true&username=$RaceUsername"
$RaceSession = Invoke-RestMethod -Method Post -Uri $RaceAuthUri -Headers $AuthHeaders -ContentType "application/json" -Body (@{ id = $RaceDeviceId } | ConvertTo-Json -Compress)
$RaceHeaders = @{ Authorization = "Bearer $($RaceSession.token)" }
$RaceCreateInner = @{
    idempotency_key = "race-create-$RunId"; hunter_name = "Race Trace"; class_id = "warrant_breaker"; species_id = "mothari"; appearance = $Appearance
} | ConvertTo-Json -Depth 10 -Compress
$RaceCreateBody = ConvertTo-Json -InputObject $RaceCreateInner -Compress
$RaceCreates = @(1..2 | ForEach-Object -Parallel {
    $Envelope = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:7350/v2/rpc/cg_character_create" -Headers $using:RaceHeaders -ContentType "application/json" -Body $using:RaceCreateBody
    return [string]$Envelope.payload | ConvertFrom-Json
} -ThrottleLimit 2)
if ($RaceCreates.Count -ne 2 -or @($RaceCreates | Where-Object { $_.revision -eq 0 }).Count -ne 2 -or @($RaceCreates | Where-Object { $_.idempotent_replay -eq $true }).Count -ne 1) {
    throw "Concurrent identical creation did not resolve to one creation and one idempotent replay."
}
$RaceAccountId = [string]$RaceCreates[0].account_id
$RaceCommandInner = @{
    api_version = 1; command_id = "race-commit-$RunId"; idempotency_key = "race-receipt-$RunId"; operation = "profile_commit"
    session_id = $RaceAccountId; shard_id = "international_1"; character_id = $RaceAccountId; expected_revision = 0
    payload = @{ hunter_name = "Race Vector"; appearance = @{ palette = "warm"; eyes = "wide"; feature = "subtle"; marking = "spots" } }
} | ConvertTo-Json -Depth 10 -Compress
$RaceCommandBody = ConvertTo-Json -InputObject $RaceCommandInner -Compress
$RaceCommits = @(1..2 | ForEach-Object -Parallel {
    $Envelope = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:7350/v2/rpc/cg_character_commit" -Headers $using:RaceHeaders -ContentType "application/json" -Body $using:RaceCommandBody
    return [string]$Envelope.payload | ConvertFrom-Json
} -ThrottleLimit 2)
$RaceStatuses = @($RaceCommits | ForEach-Object { [string]$_.status })
if ($RaceCommits.Count -ne 2 -or -not $RaceStatuses.Contains("accepted") -or -not $RaceStatuses.Contains("duplicate") -or @($RaceCommits | Where-Object { $_.server_revision -eq 1 }).Count -ne 2) {
    throw "Concurrent identical commit did not resolve to one acceptance and one duplicate receipt."
}

Write-Host "PASS: local Nakama auth/session, UTC, owned character authority, concurrent idempotency, conflicts, and progression forgery rejection are valid."
