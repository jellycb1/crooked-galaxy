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
$AgencyDirectoryBefore = Invoke-StagingRpc -Name "cg_agency_directory" -Payload @{ cursor = "" }
if ([string]$AgencyDirectoryBefore.authority -ne "server" -or [string]$AgencyDirectoryBefore.shard_id -ne "international_1" -or @($AgencyDirectoryBefore.agencies).Count -gt 25) {
    throw "Staging Agency directory did not return a bounded server page."
}
$AgencyCreatePayload = @{
    api_version = 1; command_id = "stage-agency-$RunId"; idempotency_key = "stage-agency-receipt-$RunId"; operation = "agency_create"
    session_id = $AccountId; shard_id = "international_1"; character_id = $AccountId; expected_revision = 0
    payload = @{ name = "Stage $($RunId.Substring(0, 8))"; recruitment_mode = "application"; preferred_locale = "multi" }
}
$AgencyCreated = Invoke-StagingRpc -Name "cg_agency_create" -Payload $AgencyCreatePayload
$AgencyReplay = Invoke-StagingRpc -Name "cg_agency_create" -Payload $AgencyCreatePayload
if ([string]$AgencyCreated.status -ne "accepted" -or [int]$AgencyCreated.server_revision -ne 1 -or [string]$AgencyReplay.status -ne "duplicate") {
    throw "Staging Agency creation did not preserve its independent revision and exact idempotency."
}
$AgencyMembership = Invoke-StagingRpc -Name "cg_agency_membership_get" -Payload @{}
if ([string]$AgencyMembership.membership_state -ne "member" -or [string]$AgencyMembership.role_id -ne "director" `
    -or [int]$AgencyMembership.revision -ne 1 -or @($AgencyMembership.agency.members).Count -ne 1 `
    -or [string]$AgencyMembership.agency.members[0].character_id -ne $AccountId) {
    throw "Staging Agency did not bind its creator as the sole canonical Director."
}
$AgencyCursor = ""
$CreatedSummary = @()
for ($AgencyPageIndex = 0; $AgencyPageIndex -lt 20 -and $CreatedSummary.Count -eq 0; $AgencyPageIndex++) {
    $AgencyDirectoryAfter = Invoke-StagingRpc -Name "cg_agency_directory" -Payload @{ cursor = $AgencyCursor }
    $CreatedSummary = @($AgencyDirectoryAfter.agencies | Where-Object { [string]$_.agency_id -eq [string]$AgencyMembership.agency_id })
    $AgencyCursor = [string]$AgencyDirectoryAfter.next_cursor
    if ([string]::IsNullOrEmpty($AgencyCursor)) { break }
}
if ($CreatedSummary.Count -ne 1 -or [int]$CreatedSummary[0].member_count -ne 1 -or [string]$CreatedSummary[0].recruitment_mode -ne "application") {
    throw "Created staging Agency is missing from the bounded roster-free directory."
}
$DirectorRpcHeaders = $RpcHeaders
$ApplicantDeviceId = "cg-staging-applicant-$RunId"
$ApplicantUsername = "stage_ap_$($RunId.Substring(0, 17))"
$ApplicantAuthUri = "$BaseUri/v2/account/authenticate/device?create=true&username=$ApplicantUsername"
$ApplicantSession = Invoke-RestMethod -Method Post -Uri $ApplicantAuthUri -Headers $AuthHeaders -ContentType "application/json" -Body (@{ id = $ApplicantDeviceId } | ConvertTo-Json -Compress)
if ([string]::IsNullOrWhiteSpace([string]$ApplicantSession.token)) { throw "Staging Agency applicant authentication returned no session token." }
$RpcHeaders = @{ Authorization = "Bearer $($ApplicantSession.token)" }
$ApplicantMissing = Invoke-StagingRpc -Name "cg_character_get" -Payload @{}
$ApplicantId = [string]$ApplicantMissing.account_id
$ApplicantCreated = Invoke-StagingRpc -Name "cg_character_create" -Payload @{
    idempotency_key = "stage-applicant-create-$RunId"; hunter_name = "Stage Applicant"; class_id = "contract_hacker"; species_id = "synthetic"; appearance = $Appearance
}
if ($ApplicantCreated.created -ne $true -or [string]$ApplicantCreated.character_id -ne $ApplicantId) {
    throw "Staging Agency applicant did not receive an owned character."
}
$AgencyApplyPayload = @{
    api_version = 1; command_id = "stage-agency-apply-$RunId"; idempotency_key = "stage-agency-apply-receipt-$RunId"; operation = "agency_apply"
    session_id = $ApplicantId; shard_id = "international_1"; character_id = $ApplicantId; expected_revision = 0
    payload = @{ agency_id = [string]$AgencyMembership.agency_id }
}
$AgencyApplied = Invoke-StagingRpc -Name "cg_agency_apply" -Payload $AgencyApplyPayload
$AgencyApplyReplay = Invoke-StagingRpc -Name "cg_agency_apply" -Payload $AgencyApplyPayload
if ([string]$AgencyApplied.status -ne "accepted" -or [int]$AgencyApplied.server_revision -ne 1 -or [string]$AgencyApplyReplay.status -ne "duplicate") {
    throw "Staging Agency application did not preserve exact idempotent intent."
}
$ApplicantMembership = Invoke-StagingRpc -Name "cg_agency_membership_get" -Payload @{}
if ([string]$ApplicantMembership.membership_state -ne "application_pending" -or [string]$ApplicantMembership.agency_id -ne [string]$AgencyMembership.agency_id `
    -or [int]$ApplicantMembership.revision -ne 1 -or -not [string]::IsNullOrEmpty([string]$ApplicantMembership.role_id) `
    -or @($ApplicantMembership.agency.PSObject.Properties).Count -ne 0) {
    throw "Staging application did not expose the canonical roster-free pending snapshot."
}
$RpcHeaders = $DirectorRpcHeaders
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

Write-Host "PASS: public TLS, HSTS, authentication, UTC, character/build ownership, Agency creation/directory/application, authority rejection, revisions, idempotency, and conflicts pass on staging."
