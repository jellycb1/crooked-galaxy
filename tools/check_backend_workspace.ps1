$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BackendRoot = Join-Path $ProjectRoot "backend"
$Required = @(
    "README.md", "stack-lock.json", ".env.example", ".dockerignore", "Dockerfile", "docker-compose.yml",
    "local.yml", "package.json", "tsconfig.json", "src/main.ts", "prepare_local_env.ps1", "test_local.ps1", "test_godot_client.ps1",
    ".env.staging.example", "staging.yml", "Caddyfile.staging", "docker-compose.staging.yml",
    "prepare_staging_env.ps1", "validate_staging.ps1", "backup_staging.ps1", "restore_drill.ps1", "test_staging.ps1",
    "bootstrap_hetzner_staging.sh", "finalize_hetzner_ssh.sh"
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
$StagingCompose = Get-Content -LiteralPath (Join-Path $BackendRoot "docker-compose.staging.yml") -Raw
$StagingProxy = Get-Content -LiteralPath (Join-Path $BackendRoot "Caddyfile.staging") -Raw
$StagingEnvironmentExample = Get-Content -LiteralPath (Join-Path $BackendRoot ".env.staging.example") -Raw
$StagingEnvironmentPreparer = Get-Content -LiteralPath (Join-Path $BackendRoot "prepare_staging_env.ps1") -Raw
$StagingValidator = Get-Content -LiteralPath (Join-Path $BackendRoot "validate_staging.ps1") -Raw
$StagingBackup = Get-Content -LiteralPath (Join-Path $BackendRoot "backup_staging.ps1") -Raw
$RestoreDrill = Get-Content -LiteralPath (Join-Path $BackendRoot "restore_drill.ps1") -Raw
$HostBootstrap = Get-Content -LiteralPath (Join-Path $BackendRoot "bootstrap_hetzner_staging.sh") -Raw
$SshFinalizer = Get-Content -LiteralPath (Join-Path $BackendRoot "finalize_hetzner_ssh.sh") -Raw
if (-not $Dockerfile.Contains("nakama:$($Lock.nakama_server)") -or
    [string]$Package.devDependencies.'nakama-runtime' -ne "github:heroiclabs/nakama-common#v$($Lock.nakama_common_runtime_types)" -or
    -not $ServerRules.Contains("SERVER_VERSION := `"$($Lock.nakama_server)`"") -or
    -not $ServerRules.Contains("RUNTIME_TYPES_VERSION := `"$($Lock.nakama_common_runtime_types)`"")) {
    throw "Backend server/runtime version pins diverged."
}
if (-not $StagingCompose.Contains("caddy:$($Lock.caddy)@$($Lock.caddy_image_digest)") -or -not $Dockerfile.Contains("COPY staging.yml /nakama/data/staging.yml")) {
    throw "Staging proxy or Nakama configuration pin diverged."
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
    if (-not $EnvironmentExample.Contains("$SecretKey=") -or -not $StagingEnvironmentExample.Contains("$SecretKey=") -or -not $Compose.Contains("`${$SecretKey}") -or -not $StagingCompose.Contains("`${$SecretKey}")) {
        throw "Backend secret contract is incomplete for $SecretKey."
    }
}
foreach ($IgnoredPath in @(".env", ".env.staging", "node_modules/", "build/", "data/", "backups/")) {
    if (-not $DockerIgnore.Contains($IgnoredPath)) {
        throw "Docker build context does not exclude $IgnoredPath."
    }
}
foreach ($StagingGuard in @(
    '127.0.0.1:7351:7351', 'internal: true', 'read_only: true', '80:80', '443:443',
    './Caddyfile.staging:/etc/caddy/Caddyfile:ro', './backups:/backups'
)) {
    if (-not $StagingCompose.Contains($StagingGuard)) { throw "Staging topology guard is missing: $StagingGuard" }
}
foreach ($UnsafeBinding in @('5432:5432', '7350:7350', '0.0.0.0:7351')) {
    if ($StagingCompose.Contains($UnsafeBinding)) { throw "Staging topology exposes an internal service: $UnsafeBinding" }
}
foreach ($ProxyGuard in @('admin off', 'max_size 128KB', 'reverse_proxy nakama:7350', 'health_uri /healthcheck', 'Strict-Transport-Security')) {
    if (-not $StagingProxy.Contains($ProxyGuard)) { throw "TLS edge guard is missing: $ProxyGuard" }
}
foreach ($ValidationGuard in @("EndsWith('.invalid')", "EndsWith('.test')", 'HashSet[string]', 'may not reuse one secret', 'published:\s*"?7350')) {
    if (-not $StagingValidator.Contains($ValidationGuard)) { throw "Staging environment validation guard is missing: $ValidationGuard" }
}
foreach ($RestoreGuard in @('Get-FileHash', '--exit-on-error', 'information_schema.tables', 'cg-restore-drill-', 'volume rm')) {
    if (-not $RestoreDrill.Contains($RestoreGuard)) { throw "Isolated restore guard is missing: $RestoreGuard" }
}
foreach ($BackupGuard in @('.cg-write-probe-', 'must be writable by the deployment operator', 'PartialChecksumPath', 'Remove-Item -LiteralPath')) {
    if (-not $StagingEnvironmentPreparer.Contains($BackupGuard) -and -not $StagingBackup.Contains($BackupGuard)) { throw "Staging backup ownership or rollback guard is missing: $BackupGuard" }
}
foreach ($BootstrapGuard in @('Ubuntu 24.04 x86_64', 'PasswordAuthentication no', 'PermitRootLogin prohibit-password', 'download.docker.com/linux/ubuntu', 'packages.microsoft.com/config/ubuntu', 'unattended-upgrades', 'max-size')) {
    if (-not $HostBootstrap.Contains($BootstrapGuard)) { throw "Hetzner bootstrap guard is missing: $BootstrapGuard" }
}
foreach ($FinalGuard in @('SUDO_USER', 'cgdeploy', 'PermitRootLogin no', 'AllowUsers cgdeploy', 'sshd -t')) {
    if (-not $SshFinalizer.Contains($FinalGuard)) { throw "Hetzner SSH finalizer guard is missing: $FinalGuard" }
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
$TrackedSecrets = @(& git -C $ProjectRoot ls-files -- "backend/.env" "backend/.env.staging" "backend/node_modules" "backend/build" "backend/data" "backend/backups")
if ($LASTEXITCODE -ne 0 -or $TrackedSecrets.Count -gt 0) {
    throw "Backend secret or generated state is tracked: $($TrackedSecrets -join ', ')"
}
Write-Host "PASS: backend workspace is pinned, secret-safe, complete, and excluded from game exports."
