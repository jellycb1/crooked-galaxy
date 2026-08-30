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

$Health = Invoke-WebRequest -UseBasicParsing -Method Get -Uri "http://127.0.0.1:7350/healthcheck"
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
$AgencyMembership = Invoke-CgRpc -Name "cg_agency_membership_get" -Payload @{}
if ([string]$AgencyMembership.account_id -ne $AccountId -or [string]$AgencyMembership.character_id -ne $AccountId `
    -or [string]$AgencyMembership.membership_state -ne "none" -or [int]$AgencyMembership.revision -ne 0 `
    -or -not [string]::IsNullOrEmpty([string]$AgencyMembership.agency_id) -or @($AgencyMembership.agency.PSObject.Properties).Count -ne 0) {
    throw "Fresh character did not return the canonical independent no-Agency membership snapshot."
}
$AgencyDirectoryBefore = Invoke-CgRpc -Name "cg_agency_directory" -Payload @{ cursor = "" }
if ([string]$AgencyDirectoryBefore.authority -ne "server" -or [string]$AgencyDirectoryBefore.shard_id -ne "international_1" -or @($AgencyDirectoryBefore.agencies).Count -gt 25) {
    throw "Agency directory did not return a bounded server page."
}
$AgencyCreatePayload = @{
    api_version = 1; command_id = "agency-create-$RunId"; idempotency_key = "agency-create-receipt-$RunId"; operation = "agency_create"
    session_id = $AccountId; shard_id = "international_1"; character_id = $AccountId; expected_revision = 0
    payload = @{ name = "Nova $($RunId.Substring(0, 8))"; recruitment_mode = "application"; preferred_locale = "multi" }
}
$AgencyCreated = Invoke-CgRpc -Name "cg_agency_create" -Payload $AgencyCreatePayload
$AgencyReplay = Invoke-CgRpc -Name "cg_agency_create" -Payload $AgencyCreatePayload
if ([string]$AgencyCreated.status -ne "accepted" -or [int]$AgencyCreated.server_revision -ne 1 -or [string]$AgencyReplay.status -ne "duplicate") {
    throw "Agency creation did not preserve its independent revision and exact idempotency."
}
$AgencyMembership = Invoke-CgRpc -Name "cg_agency_membership_get" -Payload @{}
if ([string]$AgencyMembership.membership_state -ne "member" -or [string]$AgencyMembership.role_id -ne "director" `
    -or [int]$AgencyMembership.revision -ne 1 -or @($AgencyMembership.agency.members).Count -ne 1 `
    -or [string]$AgencyMembership.agency.members[0].character_id -ne $AccountId) {
    throw "Created Agency did not bind its creator as the sole canonical Director."
}
$AgencyCursor = ""
$CreatedSummary = @()
for ($AgencyPageIndex = 0; $AgencyPageIndex -lt 20 -and $CreatedSummary.Count -eq 0; $AgencyPageIndex++) {
    $AgencyDirectoryAfter = Invoke-CgRpc -Name "cg_agency_directory" -Payload @{ cursor = $AgencyCursor }
    $CreatedSummary = @($AgencyDirectoryAfter.agencies | Where-Object { [string]$_.agency_id -eq [string]$AgencyMembership.agency_id })
    $AgencyCursor = [string]$AgencyDirectoryAfter.next_cursor
    if ([string]::IsNullOrEmpty($AgencyCursor)) { break }
}
if ($CreatedSummary.Count -ne 1 -or [int]$CreatedSummary[0].member_count -ne 1 -or [string]$CreatedSummary[0].recruitment_mode -ne "application") {
    throw "Created Agency is missing from the bounded roster-free directory."
}
$DirectorRpcHeaders = $RpcHeaders
$ApplicantDeviceId = "cg-local-applicant-$RunId"
$ApplicantUsername = "ap_$($RunId.Substring(0, 20))"
$ApplicantAuthUri = "http://127.0.0.1:7350/v2/account/authenticate/device?create=true&username=$ApplicantUsername"
$ApplicantSession = Invoke-RestMethod -Method Post -Uri $ApplicantAuthUri -Headers $AuthHeaders -ContentType "application/json" -Body (@{ id = $ApplicantDeviceId } | ConvertTo-Json -Compress)
if ([string]::IsNullOrWhiteSpace([string]$ApplicantSession.token)) { throw "Agency applicant authentication returned no session token." }
$RpcHeaders = @{ Authorization = "Bearer $($ApplicantSession.token)" }
$ApplicantMissing = Invoke-CgRpc -Name "cg_character_get" -Payload @{}
$ApplicantId = [string]$ApplicantMissing.account_id
$ApplicantCreated = Invoke-CgRpc -Name "cg_character_create" -Payload @{
    idempotency_key = "applicant-create-$RunId"; hunter_name = "Nova Applicant"; class_id = "contract_hacker"; species_id = "synthetic"; appearance = $Appearance
}
if ($ApplicantCreated.created -ne $true -or [string]$ApplicantCreated.character_id -ne $ApplicantId) {
    throw "Agency applicant did not receive an owned launch character."
}
$AgencyApplyPayload = @{
    api_version = 1; command_id = "agency-apply-$RunId"; idempotency_key = "agency-apply-receipt-$RunId"; operation = "agency_apply"
    session_id = $ApplicantId; shard_id = "international_1"; character_id = $ApplicantId; expected_revision = 0
    payload = @{ agency_id = [string]$AgencyMembership.agency_id }
}
$AgencyApplied = Invoke-CgRpc -Name "cg_agency_apply" -Payload $AgencyApplyPayload
$AgencyApplyReplay = Invoke-CgRpc -Name "cg_agency_apply" -Payload $AgencyApplyPayload
if ([string]$AgencyApplied.status -ne "accepted" -or [int]$AgencyApplied.server_revision -ne 1 -or [string]$AgencyApplyReplay.status -ne "duplicate") {
    throw "Agency application did not preserve exact intent and idempotent replay."
}
$ApplicantMembership = Invoke-CgRpc -Name "cg_agency_membership_get" -Payload @{}
if ([string]$ApplicantMembership.membership_state -ne "application_pending" -or [string]$ApplicantMembership.agency_id -ne [string]$AgencyMembership.agency_id `
    -or [int]$ApplicantMembership.revision -ne 1 -or -not [string]::IsNullOrEmpty([string]$ApplicantMembership.role_id) `
    -or @($ApplicantMembership.agency.PSObject.Properties).Count -ne 0) {
    throw "Application-only Agency did not expose the canonical roster-free pending snapshot."
}
$RpcHeaders = $DirectorRpcHeaders

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

$Economy = Invoke-CgRpc -Name "cg_economy_get" -Payload @{}
if ([int]$Economy.revision -ne 1 -or [int]$Economy.economy.fuel -ne 100 -or [int]$Economy.economy.inventory_count -ne 0) {
    throw "Initial authoritative economy snapshot is not canonical."
}
$Board = Invoke-CgRpc -Name "cg_hunt_board" -Payload @{}
if (-not ([string]$Board.board_id).StartsWith("board_") -or ([string]$Board.content_hash).Length -ne 64 -or @($Board.offers).Count -ne 3 -or [int]$Board.offers[0].duration_seconds -ne 2) {
    throw "Local authoritative hunt board did not expose three accelerated test offers."
}
$Offer = $Board.offers[0]
$AcceptPayload = @{
    api_version = 1; command_id = "hunt-accept-$RunId"; idempotency_key = "hunt-accept-receipt-$RunId"; operation = "hunt_accept"
    session_id = $AccountId; shard_id = "international_1"; character_id = $AccountId; expected_revision = 1
    payload = @{ board_id = [string]$Board.board_id; offer_id = [string]$Offer.offer_id; target_id = [string]$Offer.target_id; approach_id = "quiet_net" }
}
$HuntAccepted = Invoke-CgRpc -Name "cg_hunt_accept" -Payload $AcceptPayload
if ([string]$HuntAccepted.status -ne "accepted" -or [int]$HuntAccepted.server_revision -ne 2 -or [int]$HuntAccepted.snapshot.economy.fuel -ne 95) {
    throw "Authoritative hunt acceptance did not consume fuel exactly once."
}
$AcceptReplay = Invoke-CgRpc -Name "cg_hunt_accept" -Payload $AcceptPayload
if ([string]$AcceptReplay.status -ne "duplicate" -or [int]$AcceptReplay.snapshot.economy.fuel -ne 95) {
    throw "Hunt acceptance retry consumed fuel more than once."
}
$HuntId = [string]$HuntAccepted.snapshot.economy.active_hunt.hunt_id
$ResolvePayload = @{
    api_version = 1; command_id = "hunt-resolve-$RunId"; idempotency_key = "hunt-resolve-receipt-$RunId"; operation = "hunt_resolve"
    session_id = $AccountId; shard_id = "international_1"; character_id = $AccountId; expected_revision = 2
    payload = @{ hunt_id = $HuntId }
}
$EarlyResolve = Invoke-CgRpc -Name "cg_hunt_resolve" -Payload $ResolvePayload
if ([string]$EarlyResolve.status -ne "rejected" -or [string]$EarlyResolve.reason_code -ne "hunt_not_ready" -or [int]$EarlyResolve.server_revision -ne 2) {
    throw "Server UTC gate did not reject an early hunt resolution."
}
Start-Sleep -Milliseconds 2200
$Resolved = Invoke-CgRpc -Name "cg_hunt_resolve" -Payload $ResolvePayload
if ([string]$Resolved.status -ne "accepted" -or [int]$Resolved.server_revision -ne 3 -or $Resolved.result.won -ne $true -or [string]::IsNullOrWhiteSpace([string]$Resolved.snapshot.economy.pending_reward.reward_id)) {
    throw "Ready hunt did not create one sealed server reward."
}
$ResolveReplay = Invoke-CgRpc -Name "cg_hunt_resolve" -Payload $ResolvePayload
if ([string]$ResolveReplay.status -ne "duplicate" -or [int]$ResolveReplay.server_revision -ne 3) {
    throw "Hunt resolution was not idempotent."
}
$RewardId = [string]$Resolved.snapshot.economy.pending_reward.reward_id
$ClaimPayload = @{
    api_version = 1; command_id = "reward-claim-$RunId"; idempotency_key = "reward-claim-receipt-$RunId"; operation = "reward_claim"
    session_id = $AccountId; shard_id = "international_1"; character_id = $AccountId; expected_revision = 3
    payload = @{ hunt_id = $HuntId; reward_id = $RewardId; decision = "store" }
}
$Claimed = Invoke-CgRpc -Name "cg_reward_claim" -Payload $ClaimPayload
if ([string]$Claimed.status -ne "accepted" -or [int]$Claimed.server_revision -ne 4 -or [int]$Claimed.snapshot.economy.credits -ne 52 -or [int]$Claimed.snapshot.economy.xp -ne 49 -or [int]$Claimed.snapshot.economy.inventory_count -ne 1) {
    throw "Reward claim did not apply the server-authored standard reward exactly once."
}
$ClaimReplay = Invoke-CgRpc -Name "cg_reward_claim" -Payload $ClaimPayload
if ([string]$ClaimReplay.status -ne "duplicate" -or [int]$ClaimReplay.snapshot.economy.credits -ne 52 -or [int]$ClaimReplay.snapshot.economy.inventory_count -ne 1) {
    throw "Reward claim retry duplicated currency or inventory."
}
$EconomyFinal = Invoke-CgRpc -Name "cg_economy_get" -Payload @{}
if ([int]$EconomyFinal.revision -ne 4 -or @($EconomyFinal.economy.active_hunt.PSObject.Properties).Count -ne 0 -or @($EconomyFinal.economy.pending_reward.PSObject.Properties).Count -ne 0) {
    throw "Completed hunt left a dangling authoritative transaction."
}

$BuildAfterFirst = Invoke-CgRpc -Name "cg_build_get" -Payload @{}
$FirstItemId = [string]@($BuildAfterFirst.build.inventory)[0].id
if ([int]$BuildAfterFirst.revision -ne 4 -or [int]$BuildAfterFirst.build.stat_points -ne 0 -or @($BuildAfterFirst.build.inventory).Count -ne 1 -or [string]::IsNullOrWhiteSpace($FirstItemId)) {
    throw "Initial authoritative build snapshot is incomplete."
}
$NoPointsPayload = @{
    api_version = 1; command_id = "stats-empty-$RunId"; idempotency_key = "stats-empty-receipt-$RunId"; operation = "attribute_allocate"
    session_id = $AccountId; shard_id = "international_1"; character_id = $AccountId; expected_revision = 4
    payload = @{ allocations = @{ strength = 1 } }
}
$NoPoints = Invoke-CgRpc -Name "cg_attribute_allocate" -Payload $NoPointsPayload
if ([string]$NoPoints.status -ne "rejected" -or [string]$NoPoints.reason_code -ne "insufficient_stat_points" -or [int]$NoPoints.server_revision -ne 4) {
    throw "Server accepted attribute points the character had not earned."
}

# A second authored hunt earns level 2 and its two server-issued attribute points.
$BoardTwo = Invoke-CgRpc -Name "cg_hunt_board" -Payload @{}
$OfferTwo = $BoardTwo.offers[0]
$AcceptTwoPayload = @{
    api_version = 1; command_id = "hunt-accept-two-$RunId"; idempotency_key = "hunt-accept-two-receipt-$RunId"; operation = "hunt_accept"
    session_id = $AccountId; shard_id = "international_1"; character_id = $AccountId; expected_revision = 4
    payload = @{ board_id = [string]$BoardTwo.board_id; offer_id = [string]$OfferTwo.offer_id; target_id = [string]$OfferTwo.target_id; approach_id = "quiet_net" }
}
$AcceptedTwo = Invoke-CgRpc -Name "cg_hunt_accept" -Payload $AcceptTwoPayload
if ([string]$AcceptedTwo.status -ne "accepted" -or [int]$AcceptedTwo.server_revision -ne 5) { throw "Second hunt was not accepted." }
$HuntTwoId = [string]$AcceptedTwo.snapshot.economy.active_hunt.hunt_id
Start-Sleep -Seconds 3
$ResolveTwoPayload = @{
    api_version = 1; command_id = "hunt-resolve-two-$RunId"; idempotency_key = "hunt-resolve-two-receipt-$RunId"; operation = "hunt_resolve"
    session_id = $AccountId; shard_id = "international_1"; character_id = $AccountId; expected_revision = 5; payload = @{ hunt_id = $HuntTwoId }
}
$ResolvedTwo = Invoke-CgRpc -Name "cg_hunt_resolve" -Payload $ResolveTwoPayload
if ([string]$ResolvedTwo.status -ne "accepted" -or $ResolvedTwo.result.won -ne $true) { throw "Second deterministic starter hunt did not resolve successfully." }
$RewardTwoId = [string]$ResolvedTwo.snapshot.economy.pending_reward.reward_id
$ClaimTwoPayload = @{
    api_version = 1; command_id = "reward-two-$RunId"; idempotency_key = "reward-two-receipt-$RunId"; operation = "reward_claim"
    session_id = $AccountId; shard_id = "international_1"; character_id = $AccountId; expected_revision = 6
    payload = @{ hunt_id = $HuntTwoId; reward_id = $RewardTwoId; decision = "store" }
}
$ClaimedTwo = Invoke-CgRpc -Name "cg_reward_claim" -Payload $ClaimTwoPayload
if ([string]$ClaimedTwo.status -ne "accepted" -or [int]$ClaimedTwo.server_revision -ne 7 -or [int]$ClaimedTwo.snapshot.economy.level -ne 2 -or [int]$ClaimedTwo.snapshot.economy.inventory_count -ne 2) {
    throw "Second reward did not grant the canonical level and inventory progress."
}
$BuildLevelTwo = Invoke-CgRpc -Name "cg_build_get" -Payload @{}
$SecondItemId = [string]@($BuildLevelTwo.build.inventory)[1].id
if ([int]$BuildLevelTwo.build.stat_points -ne 2 -or [int]$BuildLevelTwo.build.base_power -ne 12 -or [string]::IsNullOrWhiteSpace($SecondItemId)) {
    throw "Level-up did not expose the server-issued build progress."
}
$AllocatePayload = @{
    api_version = 1; command_id = "stats-allocate-$RunId"; idempotency_key = "stats-allocate-receipt-$RunId"; operation = "attribute_allocate"
    session_id = $AccountId; shard_id = "international_1"; character_id = $AccountId; expected_revision = 7
    payload = @{ allocations = @{ strength = 1; vitality = 1 } }
}
$Allocated = Invoke-CgRpc -Name "cg_attribute_allocate" -Payload $AllocatePayload
if ([string]$Allocated.status -ne "accepted" -or [int]$Allocated.server_revision -ne 8 -or [int]$Allocated.snapshot.build.attributes.strength -ne 11 -or [int]$Allocated.snapshot.build.attributes.vitality -ne 11 -or [int]$Allocated.snapshot.build.stat_points -ne 0) {
    throw "Authoritative attribute allocation did not spend exactly two earned points."
}
$AllocatedReplay = Invoke-CgRpc -Name "cg_attribute_allocate" -Payload $AllocatePayload
if ([string]$AllocatedReplay.status -ne "duplicate" -or [int]$AllocatedReplay.snapshot.build.attributes.strength -ne 11) { throw "Attribute allocation retry spent points twice." }
$EquipPayload = @{
    api_version = 1; command_id = "inventory-equip-$RunId"; idempotency_key = "inventory-equip-receipt-$RunId"; operation = "inventory_equip"
    session_id = $AccountId; shard_id = "international_1"; character_id = $AccountId; expected_revision = 8; payload = @{ item_id = $FirstItemId }
}
$Equipped = Invoke-CgRpc -Name "cg_inventory_equip" -Payload $EquipPayload
$EquippedSlot = [string]@($BuildAfterFirst.build.inventory)[0].slot
if ([string]$Equipped.status -ne "accepted" -or [int]$Equipped.server_revision -ne 9 -or [string]$Equipped.snapshot.build.equipment.$EquippedSlot.id -ne $FirstItemId -or @($Equipped.snapshot.build.inventory).Count -ne 2) {
    throw "Equipping an owned item changed ownership or equipped the wrong slot."
}
$RecycleEquippedPayload = @{
    api_version = 1; command_id = "inventory-protected-$RunId"; idempotency_key = "inventory-protected-receipt-$RunId"; operation = "inventory_recycle"
    session_id = $AccountId; shard_id = "international_1"; character_id = $AccountId; expected_revision = 9; payload = @{ item_id = $FirstItemId }
}
$RecycleEquipped = Invoke-CgRpc -Name "cg_inventory_recycle" -Payload $RecycleEquippedPayload
if ([string]$RecycleEquipped.status -ne "rejected" -or [string]$RecycleEquipped.reason_code -ne "item_equipped") { throw "Equipped inventory item was not protected from recycling." }
$RecyclePayload = @{
    api_version = 1; command_id = "inventory-recycle-$RunId"; idempotency_key = "inventory-recycle-receipt-$RunId"; operation = "inventory_recycle"
    session_id = $AccountId; shard_id = "international_1"; character_id = $AccountId; expected_revision = 9; payload = @{ item_id = $SecondItemId }
}
$Recycled = Invoke-CgRpc -Name "cg_inventory_recycle" -Payload $RecyclePayload
if ([string]$Recycled.status -ne "accepted" -or [int]$Recycled.server_revision -ne 10 -or @($Recycled.snapshot.build.inventory).Count -ne 1 -or [int]$Recycled.result.scrap -lt 1) {
    throw "Authoritative recycle did not remove exactly one unprotected item."
}
$RecycledReplay = Invoke-CgRpc -Name "cg_inventory_recycle" -Payload $RecyclePayload
if ([string]$RecycledReplay.status -ne "duplicate" -or @($RecycledReplay.snapshot.build.inventory).Count -ne 1) { throw "Recycle retry removed inventory twice." }

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

Write-Host "PASS: local Nakama auth/session, UTC, owned character authority, concurrent idempotency, conflicts, forgery rejection, hunt economy, attributes, equipment, and recycling are valid."
