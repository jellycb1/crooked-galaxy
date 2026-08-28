$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot

$RequiredFiles = @(
    "AGENTS.md",
    "Notes/README.md",
    "Notes/Vision.txt",
    "Notes/ASSET_GENERATION_RULES.md",
    "Notes/UI_ASSET_INVENTORY_PT.md",
    "Notes/MONETIZATION_CONTRACT.md",
    "Notes/YEAR_ONE_CONTENT_CONTRACT.md"
)

foreach ($RelativePath in $RequiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $RelativePath) -PathType Leaf)) {
        throw "Required repository document is missing: $RelativePath"
    }
}

$ForbiddenPaths = @(
    "Notes/CROOKED_GALAXY_CODEX_MAX_AUTONOMY.txt",
    "Notes/CrookedGalaxy.apk"
)

foreach ($RelativePath in $ForbiddenPaths) {
    if (Test-Path -LiteralPath (Join-Path $ProjectRoot $RelativePath)) {
        throw "Obsolete or misplaced repository file returned: $RelativePath"
    }
}

$LegacyPayloadRoot = Join-Path $ProjectRoot "internal_reference_assets"
if (Test-Path -LiteralPath $LegacyPayloadRoot) {
    $LegacyPayloads = @(Get-ChildItem -LiteralPath $LegacyPayloadRoot -Recurse -File -Force)
    if ($LegacyPayloads.Count -gt 0) {
        throw "Obsolete internal reference payloads returned: $($LegacyPayloads.Count) file(s)"
    }
}

$TrackedBuildFiles = @(& git -C $ProjectRoot ls-files -- builds)
if ($LASTEXITCODE -ne 0) {
    throw "Could not inspect tracked build files."
}
if ($TrackedBuildFiles.Count -ne 1 -or $TrackedBuildFiles[0] -ne "builds/.gdignore") {
    throw "Only builds/.gdignore may be tracked under builds/: $($TrackedBuildFiles -join ', ')"
}

$TrackedUidFiles = @(& git -C $ProjectRoot ls-files -- "*.uid")
if ($LASTEXITCODE -ne 0) {
    throw "Could not inspect tracked Godot UID files."
}
foreach ($RelativePath in $TrackedUidFiles) {
    $UidPath = Join-Path $ProjectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $UidPath -PathType Leaf)) {
        continue
    }
    $SourcePath = Join-Path $ProjectRoot ($RelativePath -replace '\.uid$', '')
    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        throw "Orphan Godot UID file: $RelativePath"
    }
}

$TrackedGodotScripts = @(& git -C $ProjectRoot ls-files -- "scripts/*.gd" "tests/*.gd" "tools/*.gd")
if ($LASTEXITCODE -ne 0) {
    throw "Could not inspect tracked GDScript files."
}
foreach ($RelativePath in $TrackedGodotScripts) {
    if ($RelativePath.StartsWith("tools/export_pack_inspector/")) {
        continue
    }
    $UidPath = Join-Path $ProjectRoot "$RelativePath.uid"
    if (-not (Test-Path -LiteralPath $UidPath -PathType Leaf)) {
        throw "Tracked GDScript is missing its Godot UID companion: $RelativePath"
    }
}

$AuthorityMap = Get-Content -LiteralPath (Join-Path $ProjectRoot "Notes/README.md") -Raw
if (-not $AuthorityMap.Contains("AGENTS.md") -or
    -not $AuthorityMap.Contains("Relatórios arquivados") -or
    -not $AuthorityMap.Contains("Artefactos locais")) {
    throw "Notes/README.md no longer defines document authority and artifact ownership."
}

Write-Host "PASS: repository documents, generated outputs, legacy payloads, and Godot UIDs are organized."
