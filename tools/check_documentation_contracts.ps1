$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$NotesRoot = Join-Path $ProjectRoot "Notes"
$AuthorityPath = Join-Path $NotesRoot "README.md"
$AuthorityText = Get-Content -LiteralPath $AuthorityPath -Raw

$ActiveDocuments = @(
	"PROJECT_STATUS.md",
    "Vision.txt",
	"RELEASE_READINESS_CONTRACT.md",
	"LEVEL_1_30_ASSET_DELIVERY_MANIFEST.md",
    "ACCOUNT_SERVER_CONTRACT.md",
	"BACKEND_VERTICAL_SLICE_CONTRACT.md",
	"REMOTE_ECONOMY_CONTRACT.md",
	"ONLINE_BACKEND_DECISION_2026-08-29.md",
	"STAGING_RUNBOOK.md",
    "MONETIZATION_CONTRACT.md",
    "EQUIPMENT_SYSTEM_CONTRACT.md",
    "YEAR_ONE_CONTENT_CONTRACT.md",
    "RIFT_DAILY_REALITY_CONTRACT_2026-08-28.md",
    "WEEKLY_OPERATIONS_CONTRACT_2026-08-28.md",
    "NETWORK_CIRCUIT_CONTRACT_2026-08-29.md",
    "PLANET_CONTENT_PACK_PIPELINE.md",
    "XP_PACING_SIMULATION_2026-08-28.md",
    "VISUAL_DIRECTION.md",
    "UI_ASSET_INVENTORY_PT.md",
    "CHARACTER_ASSET_BRIEF_PT.txt",
    "MODULAR_CHARACTER_IMAGE_RULES.md",
    "ASSET_GENERATION_RULES.md"
)

foreach ($FileName in $ActiveDocuments) {
    $Path = Join-Path $NotesRoot $FileName
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Active document is missing: Notes/$FileName"
    }
    $Opening = (Get-Content -LiteralPath $Path -TotalCount 8) -join "`n"
    if ($Opening -notmatch '(?im)^\s*(status|estado):') {
        throw "Active document does not declare its status near the top: Notes/$FileName"
    }
    if (-not $AuthorityText.Contains($FileName)) {
        throw "Active document is absent from Notes/README.md: $FileName"
    }
}

$Unclassified = @(
    Get-ChildItem -LiteralPath $NotesRoot -File |
        Where-Object { $_.Name -ne "README.md" -and -not $AuthorityText.Contains($_.Name) } |
        Select-Object -ExpandProperty Name
)
if ($Unclassified.Count -gt 0) {
    throw "Notes/README.md does not classify: $($Unclassified -join ', ')"
}

$RepositoryDocuments = @(
    Get-ChildItem -LiteralPath $NotesRoot -File |
        Where-Object { $_.Extension -in ".md", ".txt" }
)
$RepositoryDocuments += Get-Item -LiteralPath (Join-Path $ProjectRoot "AGENTS.md")
$RepositoryDocuments += Get-Item -LiteralPath (Join-Path $ProjectRoot "README.md")

foreach ($Document in $RepositoryDocuments) {
    $Text = Get-Content -LiteralPath $Document.FullName -Raw
    $Matches = [regex]::Matches($Text, 'Notes/([A-Za-z0-9_.-]+\.(?:md|txt))')
    foreach ($Match in $Matches) {
        $ReferencedPath = Join-Path $NotesRoot $Match.Groups[1].Value
        if (-not (Test-Path -LiteralPath $ReferencedPath -PathType Leaf)) {
            throw "Broken Notes reference in $($Document.Name): Notes/$($Match.Groups[1].Value)"
        }
    }
}

$AgentsText = Get-Content -LiteralPath (Join-Path $ProjectRoot "AGENTS.md") -Raw
$GateText = Get-Content -LiteralPath (Join-Path $NotesRoot "ASSET_GENERATION_RULES.md") -Raw
$VisionText = Get-Content -LiteralPath (Join-Path $NotesRoot "Vision.txt") -Raw
$WeeklyText = Get-Content -LiteralPath (Join-Path $NotesRoot "WEEKLY_OPERATIONS_CONTRACT_2026-08-28.md") -Raw
$VisualText = Get-Content -LiteralPath (Join-Path $NotesRoot "VISUAL_DIRECTION.md") -Raw
$InventoryText = Get-Content -LiteralPath (Join-Path $NotesRoot "UI_ASSET_INVENTORY_PT.md") -Raw
$ReadmePath = Join-Path $ProjectRoot "README.md"
$ReadmeText = Get-Content -LiteralPath $ReadmePath -Raw
$ReadmeLines = @(Get-Content -LiteralPath $ReadmePath)
$SyncText = Get-Content -LiteralPath (Join-Path $ProjectRoot "scripts/profile_sync_rules.gd") -Raw
$AccountContractText = Get-Content -LiteralPath (Join-Path $NotesRoot "ACCOUNT_SERVER_CONTRACT.md") -Raw
$ReleaseText = Get-Content -LiteralPath (Join-Path $NotesRoot "RELEASE_READINESS_CONTRACT.md") -Raw
$DeliveryManifestText = Get-Content -LiteralPath (Join-Path $NotesRoot "LEVEL_1_30_ASSET_DELIVERY_MANIFEST.md") -Raw
$MonetizationText = Get-Content -LiteralPath (Join-Path $NotesRoot "MONETIZATION_CONTRACT.md") -Raw
$OnlineDecisionText = Get-Content -LiteralPath (Join-Path $NotesRoot "ONLINE_BACKEND_DECISION_2026-08-29.md") -Raw
$StagingText = Get-Content -LiteralPath (Join-Path $NotesRoot "STAGING_RUNBOOK.md") -Raw
$AgencyText = Get-Content -LiteralPath (Join-Path $NotesRoot "BOUNTY_AGENCY_CONTRACT.md") -Raw

if (-not $AgentsText.Contains("The project owner authorizes Codex") -or $AgentsText.Contains("Codex must not generate")) {
    throw "AGENTS.md has conflicting visual-asset authorization instructions."
}
if ($AuthorityText.Contains("proibição de Codex") -or
	$ReadmeText.Contains("Codex preserves code-native fallbacks and does not create") -or
	$AccountContractText.Contains("MIGRATION_REQUEST_IMPORT")) {
	throw "Active documentation has returned to an obsolete authorship or save-import boundary."
}
if (-not $GateText.Contains("the project owner authorizes Codex") -or $GateText.Contains("Codex must not generate")) {
    throw "The visual intake gate no longer matches the project owner's asset authorization."
}
if ($VisionText.Contains("used as Placeholders keeping") -or $WeeklyText.Contains("45 caçadas semanais")) {
    throw "An obsolete product or pacing claim returned to an active contract."
}
if (-not $ReleaseText.Contains("Mecanicamente completo") -or
	-not $ReleaseText.Contains("Primeiro slice de produção: níveis 1–30") -or
	-not $ReleaseText.Contains("151 entregas visuais finais") -or
	-not $ReleaseText.Contains("tools/audit_release_readiness.gd") -or
	-not $ReleaseText.Contains("ainda não está visualmente completo nem pronto para lançamento")) {
	throw "Release readiness no longer separates mechanical completion from production and launch readiness."
}
if (-not $DeliveryManifestText.Contains('`style_lock` — 17 files') -or
	-not $DeliveryManifestText.Contains('`identity` — 86 files') -or
	-not $DeliveryManifestText.Contains('`worlds` — 38 files') -or
	-not $DeliveryManifestText.Contains('`transports` — 4 vehicle') -or
	-not $DeliveryManifestText.Contains('`rift` — the first 6') -or
	-not $DeliveryManifestText.Contains("export_release_asset_manifest.gd")) {
	throw "The level 1-30 art handoff no longer matches the executable 151-delivery manifest."
}
if ($ReadmeText.Contains("never levels, attributes, victory, combat probability, exclusive superior gear, Fenda attempts") -or
	$VisionText.Contains("or post-result combat rerolls.") -or
	$MonetizationText.Contains("23 707 Créditos") -or
	$WeeklyText.Contains("33–34 caçadas por semana")) {
	throw "An obsolete monetization, workshop, or weekly pacing claim returned."
}
if (-not $MonetizationText.Contains("24 883 Créditos") -or
	-not $WeeklyText.Contains("aproximadamente 27 caçadas por semana") -or
	-not $VisionText.Contains("sole active post-result exception")) {
	throw "Active monetization and pacing contracts no longer match the audited model."
}
if ($OnlineDecisionText.Contains("No remote environment") -or
	$StagingText.Contains("transfer automation remains a pending gate") -or
	$AgencyText.Contains("Não existe ainda backend, membership")) {
	throw "A pre-staging backend status returned to active documentation."
}
if ($VisualText.Contains("the current class slice is capped") -or $InventoryText.Contains("Fichas Warp") -or $InventoryText.Contains("atual: 28 identidades")) {
    throw "Visual documentation contains obsolete runtime or vocabulary claims."
}
if ($ReadmeLines.Count -gt 220 -or
    -not $ReadmeText.Contains("Notes/README.md") -or
    $ReadmeText.Contains("transactional decisions hide the dock")) {
    throw "README.md has returned to an oversized or conflicting implementation chronicle."
}
if (-not $SyncText.Contains('MIGRATION_ARCHIVE_AND_START_REMOTE') -or
    $SyncText.Contains('MIGRATION_REQUEST_IMPORT') -or
    -not $AccountContractText.Contains('never imported or merged into the online economy')) {
    throw "The device-save archival cutover no longer fails closed against online economy import."
}

Write-Host "PASS: active instructions are classified, linked, status-marked, and contradiction-free."
