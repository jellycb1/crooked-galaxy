param(
    [string]$EnvironmentPath = (Join-Path $PSScriptRoot ".env.staging")
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

& (Join-Path $PSScriptRoot "validate_staging.ps1") -EnvironmentPath $EnvironmentPath
$BackupRoot = Join-Path $PSScriptRoot "backups"
New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
$Timestamp = [DateTime]::UtcNow.ToString("yyyyMMddTHHmmssZ")
$FileName = "nakama-staging-$Timestamp.dump"
if ($FileName -notmatch '^nakama-staging-[0-9]{8}T[0-9]{6}Z\.dump$') { throw "Unsafe backup filename." }

$Docker = Get-Command docker -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
if ([string]::IsNullOrWhiteSpace($Docker)) {
    $Candidate = Join-Path $env:LOCALAPPDATA "Programs\DockerDesktop\resources\bin\docker.exe"
    if (Test-Path -LiteralPath $Candidate) { $Docker = $Candidate }
}
$DockerBin = Split-Path -Parent $Docker
$env:PATH = "$DockerBin;$env:PATH"
$ComposeArgs = @("compose", "--env-file", $EnvironmentPath, "-f", (Join-Path $PSScriptRoot "docker-compose.staging.yml"))
& $Docker @ComposeArgs exec -T postgres pg_dump -U postgres -d nakama --format=custom --file="/backups/$FileName.partial"
if ($LASTEXITCODE -ne 0) { throw "PostgreSQL staging backup failed." }
& $Docker @ComposeArgs exec -T postgres pg_restore --list "/backups/$FileName.partial" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Generated staging backup failed pg_restore structural validation." }
& $Docker @ComposeArgs exec -T postgres mv "/backups/$FileName.partial" "/backups/$FileName"
if ($LASTEXITCODE -ne 0) { throw "Validated staging backup could not be finalized." }
$BackupPath = Join-Path $BackupRoot $FileName
if (-not (Test-Path -LiteralPath $BackupPath -PathType Leaf) -or (Get-Item -LiteralPath $BackupPath).Length -lt 1024) {
    throw "Finalized staging backup is missing or implausibly small."
}
$Digest = (Get-FileHash -LiteralPath $BackupPath -Algorithm SHA256).Hash.ToLowerInvariant()
[System.IO.File]::WriteAllText("$BackupPath.sha256", "$Digest  $FileName`n", [System.Text.UTF8Encoding]::new($false))
Write-Host "PASS: staging database backup completed and structurally verified: $FileName"
