param(
    [string]$EnvironmentPath = (Join-Path $PSScriptRoot ".env.staging")
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

& (Join-Path $PSScriptRoot "validate_staging.ps1") -EnvironmentPath $EnvironmentPath
$Values = @{}
foreach ($Line in Get-Content -LiteralPath $EnvironmentPath) {
    if ($Line -match '^([^#=]+)=(.+)$') { $Values[$Matches[1]] = $Matches[2] }
}
$BaseUri = "https://$([string]$Values.CG_STAGING_DOMAIN)"
$ServerKey = [string]$Values.CG_NAKAMA_SERVER_KEY

$Health = Invoke-WebRequest -UseBasicParsing -Method Get -Uri "$BaseUri/healthcheck"
if ($Health.StatusCode -ne 200 -or [string]$Health.Headers.'Strict-Transport-Security' -notmatch 'max-age=31536000') {
    throw "Staging TLS edge did not return healthy Nakama plus the required HSTS policy."
}

$RunId = [Guid]::NewGuid().ToString("N")
$DeviceId = "cg-staging-smoke-$RunId"
$Username = "stage_$($RunId.Substring(0, 20))"
$BasicBytes = [Text.Encoding]::UTF8.GetBytes("${ServerKey}:")
$Basic = [Convert]::ToBase64String($BasicBytes)
$AuthHeaders = @{ Authorization = "Basic $Basic" }
$AuthUri = "$BaseUri/v2/account/authenticate/device?create=true&username=$Username"
$Session = Invoke-RestMethod -Method Post -Uri $AuthUri -Headers $AuthHeaders -ContentType "application/json" -Body (@{ id = $DeviceId } | ConvertTo-Json -Compress)
if ([string]::IsNullOrWhiteSpace([string]$Session.token)) { throw "Staging authentication returned no session token." }
$RpcHeaders = @{ Authorization = "Bearer $($Session.token)" }

function Invoke-StagingRpc {
    param([Parameter(Mandatory = $true)][string]$Name, [Parameter(Mandatory = $true)][hashtable]$Payload)
    $InnerJson = $Payload | ConvertTo-Json -Depth 10 -Compress
    $OuterJson = ConvertTo-Json -InputObject $InnerJson -Compress
    $Envelope = Invoke-RestMethod -Method Post -Uri "$BaseUri/v2/rpc/$Name" -Headers $RpcHeaders -ContentType "application/json" -Body $OuterJson
    return [string]$Envelope.payload | ConvertFrom-Json
}

$Before = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$Clock = Invoke-StagingRpc -Name "cg_clock" -Payload @{}
$After = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
if ([string]$Clock.authority -ne "server" -or [string]$Clock.shard_id -ne "international_1" -or [int64]$Clock.server_unix_ms -lt $Before -or [int64]$Clock.server_unix_ms -gt $After) {
    throw "Staging authoritative UTC envelope is invalid."
}

$Missing = Invoke-StagingRpc -Name "cg_character_get" -Payload @{}
if ($Missing.exists -ne $false) { throw "Fresh staging account unexpectedly owns a character." }
$AccountId = [string]$Missing.account_id
$Appearance = @{ palette = "native"; eyes = "standard"; feature = "classic"; marking = "clean" }
$CreatePayload = @{
    idempotency_key = "stage-create-$RunId"; hunter_name = "Stage Trace"; class_id = "orbit_gunslinger"; species_id = "starworn"; appearance = $Appearance
}
$Created = Invoke-StagingRpc -Name "cg_character_create" -Payload $CreatePayload
$Replayed = Invoke-StagingRpc -Name "cg_character_create" -Payload $CreatePayload
if ($Created.created -ne $true -or [int]$Created.revision -ne 0 -or [int]$Created.profile.credits -ne 25 -or $Replayed.idempotent_replay -ne $true) {
    throw "Staging character creation or its idempotent replay failed."
}
$Summary = Invoke-StagingRpc -Name "cg_session" -Payload @{}
if ([string]$Summary.account_id -ne $AccountId -or [string]$Summary.active_character_id -ne $AccountId -or @($Summary.owned_character_ids).Count -ne 1) {
    throw "Staging session does not bind exactly one owned active character."
}
$AgencyMembership = Invoke-StagingRpc -Name "cg_agency_membership_get" -Payload @{}
if ([string]$AgencyMembership.account_id -ne $AccountId -or [string]$AgencyMembership.character_id -ne $AccountId `
    -or [string]$AgencyMembership.membership_state -ne "none" -or [int]$AgencyMembership.revision -ne 0 `
    -or -not [string]::IsNullOrEmpty([string]$AgencyMembership.agency_id) -or @($AgencyMembership.agency.PSObject.Properties).Count -ne 0) {
    throw "Fresh staging character did not return the canonical independent no-Agency membership snapshot."
}
$Build = Invoke-StagingRpc -Name "cg_build_get" -Payload @{}
if ([int]$Build.revision -ne 0 -or [int]$Build.build.base_power -ne 10 -or [int]$Build.build.stat_points -ne 0 -or @($Build.build.inventory).Count -ne 0 -or [string]$Build.build.equipment.weapon.id -ne "starter_weapon") {
    throw "Staging exact starter build snapshot is invalid."
}
$UnearnedPoints = @{
    api_version = 1; command_id = "stage-stats-$RunId"; idempotency_key = "stage-stats-receipt-$RunId"; operation = "attribute_allocate"
    session_id = $AccountId; shard_id = "international_1"; character_id = $AccountId; expected_revision = 0
    payload = @{ allocations = @{ strength = 1 } }
}
$RejectedPoints = Invoke-StagingRpc -Name "cg_attribute_allocate" -Payload $UnearnedPoints
if ([string]$RejectedPoints.status -ne "rejected" -or [string]$RejectedPoints.reason_code -ne "insufficient_stat_points" -or [int]$RejectedPoints.server_revision -ne 0) {
    throw "Staging accepted an unearned attribute allocation."
}

$Commit = @{
    api_version = 1; command_id = "stage-commit-$RunId"; idempotency_key = "stage-receipt-$RunId"; operation = "profile_commit"
    session_id = $AccountId; shard_id = "international_1"; character_id = $AccountId; expected_revision = 0
    payload = @{ hunter_name = "Stage Vector"; appearance = @{ palette = "cool"; eyes = "narrow"; feature = "bold"; marking = "stripe" } }
}
$Accepted = Invoke-StagingRpc -Name "cg_character_commit" -Payload $Commit
$Duplicate = Invoke-StagingRpc -Name "cg_character_commit" -Payload $Commit
if ([string]$Accepted.status -ne "accepted" -or [string]$Duplicate.status -ne "duplicate" -or [int]$Accepted.server_revision -ne 1) {
    throw "Staging profile commit did not preserve atomic idempotency."
}
$Stale = $Commit.Clone()
$Stale.command_id = "stage-stale-$RunId"
$Stale.idempotency_key = "stage-stale-receipt-$RunId"
$Conflict = Invoke-StagingRpc -Name "cg_character_commit" -Payload $Stale
if ([string]$Conflict.status -ne "conflict" -or [int]$Conflict.server_revision -ne 1) {
    throw "Staging stale revision did not return the canonical conflict."
}

Write-Host "PASS: public TLS, HSTS, authentication, UTC, character/build/Agency ownership, authority rejection, revisions, idempotency, and conflicts pass on staging."
