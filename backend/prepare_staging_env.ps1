param(
    [Parameter(Mandatory = $true)][string]$Domain,
    [Parameter(Mandatory = $true)][string]$AcmeEmail
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Domain = $Domain.Trim().ToLowerInvariant()
$AcmeEmail = $AcmeEmail.Trim().ToLowerInvariant()
if ($Domain -notmatch '^(?=.{4,253}$)(?!-)(?:[a-z0-9-]+\.)+[a-z]{2,63}$' -or
    $Domain.EndsWith('.invalid') -or $Domain.EndsWith('.example') -or $Domain.EndsWith('.test') -or $Domain.EndsWith('.localhost')) {
    throw "Domain must be a real public DNS hostname reserved for staging."
}
if ($AcmeEmail -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$' -or $AcmeEmail.EndsWith('@example.invalid') -or $AcmeEmail.EndsWith('@example.test')) {
    throw "AcmeEmail must be a deliverable operator address."
}

function New-StagingSecret {
    $Bytes = [byte[]]::new(32)
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($Bytes)
    return [Convert]::ToHexString($Bytes).ToLowerInvariant()
}

$EnvironmentPath = Join-Path $PSScriptRoot ".env.staging"
if (Test-Path -LiteralPath $EnvironmentPath) {
    throw "Refusing to overwrite existing staging credentials: $EnvironmentPath"
}
$Lines = @(
    "CG_STAGING_DOMAIN=$Domain",
    "CG_ACME_EMAIL=$AcmeEmail",
    "CG_POSTGRES_PASSWORD=$(New-StagingSecret)",
    "CG_NAKAMA_SERVER_KEY=$(New-StagingSecret)",
    "CG_NAKAMA_SESSION_KEY=$(New-StagingSecret)",
    "CG_NAKAMA_REFRESH_KEY=$(New-StagingSecret)",
    "CG_NAKAMA_RUNTIME_HTTP_KEY=$(New-StagingSecret)",
    "CG_NAKAMA_CONSOLE_PASSWORD=$(New-StagingSecret)",
    "CG_NAKAMA_CONSOLE_SIGNING_KEY=$(New-StagingSecret)"
)
[System.IO.File]::WriteAllLines($EnvironmentPath, $Lines, [System.Text.UTF8Encoding]::new($false))
Write-Host "PASS: staging environment created without printing credentials. Transfer it only through a protected channel."
