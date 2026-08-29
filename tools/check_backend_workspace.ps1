$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BackendRoot = Join-Path $ProjectRoot "backend"
$Required = @(
    "README.md", "stack-lock.json", ".env.example", ".dockerignore", "Dockerfile", "docker-compose.yml",
    "local.yml", "package.json", "tsconfig.json", "src/main.ts", "prepare_local_env.ps1", "test_local.ps1", "test_godot_client.ps1"
)
foreach ($RelativePath in $Required) {
    if (-not (Test-Path -LiteralPath (Join-Path $BackendRoot $RelativePath) -PathType Leaf)) {
        throw "Backend workspace file is missing: backend/$RelativePath"
    }
}

$Lock = Get-Content -LiteralPath (Join-Path $BackendRoot "stack-lock.json") -Raw | ConvertFrom-Json
$Dockerfile = Get-Content -LiteralPath (Join-Path $BackendRoot "Dockerfile") -Raw
$Package = Get-Content -LiteralPath (Join-Path $BackendRoot "package.json") -Raw | ConvertFrom-Json
$ServerRules = Get-Content -LiteralPath (Join-Path $ProjectRoot "scripts/backend_deployment_rules.gd") -Raw
$ExportPresets = Get-Content -LiteralPath (Join-Path $ProjectRoot "export_presets.cfg") -Raw
$Compose = Get-Content -LiteralPath (Join-Path $BackendRoot "docker-compose.yml") -Raw
$LocalConfig = Get-Content -LiteralPath (Join-Path $BackendRoot "local.yml") -Raw
$EnvironmentExample = Get-Content -LiteralPath (Join-Path $BackendRoot ".env.example") -Raw
$DockerIgnore = Get-Content -LiteralPath (Join-Path $BackendRoot ".dockerignore") -Raw
$RuntimeSource = Get-Content -LiteralPath (Join-Path $BackendRoot "src/main.ts") -Raw
$DirectTest = Get-Content -LiteralPath (Join-Path $BackendRoot "test_local.ps1") -Raw
if (-not $Dockerfile.Contains("nakama:$($Lock.nakama_server)") -or
    [string]$Package.devDependencies.'nakama-runtime' -ne "github:heroiclabs/nakama-common#v$($Lock.nakama_common_runtime_types)" -or
    -not $ServerRules.Contains("SERVER_VERSION := `"$($Lock.nakama_server)`"") -or
    -not $ServerRules.Contains("RUNTIME_TYPES_VERSION := `"$($Lock.nakama_common_runtime_types)`"")) {
    throw "Backend server/runtime version pins diverged."
}
if (($ExportPresets | Select-String -Pattern 'exclude_filter="backend/\*,' -AllMatches).Matches.Count -ne 2) {
    throw "Backend workspace must stay outside Desktop and Android exports."
}
$NodeName = [regex]::Match($LocalConfig, '(?m)^name:\s*(\S+)\s*$').Groups[1].Value
if ([string]::IsNullOrWhiteSpace($NodeName) -or $NodeName.Length -gt 16) {
    throw "Nakama node name must contain 1-16 characters."
}
foreach ($Port in @("7350", "7351")) {
    if (-not $Compose.Contains("127.0.0.1:${Port}:${Port}")) {
        throw "Local Nakama port $Port must bind only to loopback."
    }
}
$SecretKeys = @(
    "CG_POSTGRES_PASSWORD", "CG_NAKAMA_SERVER_KEY", "CG_NAKAMA_SESSION_KEY",
    "CG_NAKAMA_REFRESH_KEY", "CG_NAKAMA_RUNTIME_HTTP_KEY",
    "CG_NAKAMA_CONSOLE_PASSWORD", "CG_NAKAMA_CONSOLE_SIGNING_KEY"
)
foreach ($SecretKey in $SecretKeys) {
    if (-not $EnvironmentExample.Contains("$SecretKey=") -or -not $Compose.Contains("`${$SecretKey}")) {
        throw "Backend secret contract is incomplete for $SecretKey."
    }
}
foreach ($IgnoredPath in @(".env", "node_modules/", "build/", "data/", "backups/")) {
    if (-not $DockerIgnore.Contains($IgnoredPath)) {
        throw "Docker build context does not exclude $IgnoredPath."
    }
}
foreach ($RpcName in @("cg_clock", "cg_session", "cg_character_get", "cg_character_create", "cg_character_commit")) {
    if (-not $RuntimeSource.Contains("registerRpc(`"$RpcName`"")) {
        throw "Required authoritative RPC is missing: $RpcName"
    }
}
foreach ($AuthorityGuard in @('permissionWrite: 0', 'version: "*"', 'payload.length > 4096', 'validStoredCharacter', 'Object.keys(change).length !== 2', 'credits: 25', 'xp: 0')) {
    if (-not $RuntimeSource.Contains($AuthorityGuard)) {
        throw "Character authority guard is missing: $AuthorityGuard"
    }
}
foreach ($Proof in @('idempotent_replay', 'status -ne "conflict"', 'credits = 999999', 'invalid_profile_change')) {
    if (-not $DirectTest.Contains($Proof)) {
        throw "Direct backend authority proof is missing: $Proof"
    }
}
$TrackedSecrets = @(& git -C $ProjectRoot ls-files -- "backend/.env" "backend/node_modules" "backend/build" "backend/data" "backend/backups")
if ($LASTEXITCODE -ne 0 -or $TrackedSecrets.Count -gt 0) {
    throw "Backend secret or generated state is tracked: $($TrackedSecrets -join ', ')"
}
Write-Host "PASS: backend workspace is pinned, secret-safe, complete, and excluded from game exports."
