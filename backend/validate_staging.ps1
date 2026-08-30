param(
    [string]$EnvironmentPath = (Join-Path $PSScriptRoot ".env.staging")
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if (-not (Test-Path -LiteralPath $EnvironmentPath -PathType Leaf)) {
    throw "Staging environment file not found: $EnvironmentPath"
}
$Values = @{}
foreach ($Line in Get-Content -LiteralPath $EnvironmentPath) {
    if ($Line -match '^([^#=]+)=(.+)$') { $Values[$Matches[1]] = $Matches[2] }
}
$Required = @(
    "CG_STAGING_DOMAIN", "CG_ACME_EMAIL", "CG_POSTGRES_PASSWORD", "CG_NAKAMA_SERVER_KEY",
    "CG_NAKAMA_SESSION_KEY", "CG_NAKAMA_REFRESH_KEY", "CG_NAKAMA_RUNTIME_HTTP_KEY",
    "CG_NAKAMA_CONSOLE_PASSWORD", "CG_NAKAMA_CONSOLE_SIGNING_KEY"
)
foreach ($Key in $Required) {
    if (-not $Values.ContainsKey($Key) -or [string]::IsNullOrWhiteSpace([string]$Values[$Key]) -or [string]$Values[$Key] -like 'replace_*') {
        throw "Missing or placeholder staging setting: $Key"
    }
}
$StagingDomain = ([string]$Values.CG_STAGING_DOMAIN).ToLowerInvariant()
if ($StagingDomain -notmatch '^(?=.{4,253}$)(?!-)(?:[a-z0-9-]+\.)+[a-z]{2,63}$' -or
    $StagingDomain.EndsWith('.invalid') -or $StagingDomain.EndsWith('.example') -or $StagingDomain.EndsWith('.test') -or $StagingDomain.EndsWith('.localhost')) {
    throw "Invalid staging DNS hostname."
}
$AcmeEmail = ([string]$Values.CG_ACME_EMAIL).ToLowerInvariant()
if ($AcmeEmail -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$' -or $AcmeEmail.EndsWith('@example.invalid') -or $AcmeEmail.EndsWith('@example.test')) {
    throw "Invalid or placeholder ACME operator email."
}
$UniqueSecrets = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($SecretKey in $Required | Select-Object -Skip 2) {
    if ([string]$Values[$SecretKey] -notmatch '^[a-f0-9]{64}$') {
        throw "Staging secret must be an independently generated 256-bit lowercase hexadecimal value: $SecretKey"
    }
    if (-not $UniqueSecrets.Add([string]$Values[$SecretKey])) {
        throw "Staging environments may not reuse one secret across multiple roles."
    }
}

$Docker = Get-Command docker -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
if ([string]::IsNullOrWhiteSpace($Docker)) {
    $Candidate = Join-Path $env:LOCALAPPDATA "Programs\DockerDesktop\resources\bin\docker.exe"
    if (Test-Path -LiteralPath $Candidate) { $Docker = $Candidate }
}
if ([string]::IsNullOrWhiteSpace($Docker)) { throw "Docker CLI is required to render the staging deployment." }
$DockerBin = Split-Path -Parent $Docker
$env:PATH = "$DockerBin;$env:PATH"
$Rendered = & $Docker compose --env-file $EnvironmentPath -f (Join-Path $PSScriptRoot "docker-compose.staging.yml") config 2>&1
if ($LASTEXITCODE -ne 0) { throw "Docker Compose rejected staging configuration.`n$($Rendered -join [Environment]::NewLine)" }
$RenderedText = $Rendered -join "`n"
if ($RenderedText.Contains("replace_with_") -or
    $RenderedText -notmatch '(?s)host_ip:\s*127\.0\.0\.1.{0,160}target:\s*7351.{0,80}published:\s*"7351"' -or
    $RenderedText -match '(?m)^\s*published:\s*"?7350"?\s*$') {
    throw "Rendered staging topology exposes a placeholder or unsafe Nakama port."
}
Write-Host "PASS: staging secrets, DNS shape, pinned topology, private database, loopback console, and public TLS edge render correctly."
