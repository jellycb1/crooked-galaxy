$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$NotesRoot = Join-Path $ProjectRoot "Notes"
$AuthorityPath = Join-Path $NotesRoot "README.md"
$AuthorityText = Get-Content -LiteralPath $AuthorityPath -Raw

$ActiveDocuments = @(
    "Vision.txt",
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

if (-not $AgentsText.Contains("Codex must not generate") -or $AgentsText.Contains("Generate one draft")) {
    throw "AGENTS.md has conflicting visual-authorship instructions."
}
if (-not $GateText.Contains("Codex must not generate") -or $GateText.Contains("### 2. Generate one draft")) {
    throw "The visual intake gate has reverted to asset-generation instructions."
}
if ($VisionText.Contains("used as Placeholders keeping") -or $WeeklyText.Contains("45 caçadas semanais")) {
    throw "An obsolete product or pacing claim returned to an active contract."
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
