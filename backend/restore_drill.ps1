param(
    [Parameter(Mandatory = $true)][string]$BackupPath
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$BackupRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "backups")).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
$ResolvedBackup = [System.IO.Path]::GetFullPath($BackupPath)
if (-not $ResolvedBackup.StartsWith($BackupRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -or
    [System.IO.Path]::GetExtension($ResolvedBackup) -ne ".dump" -or
    -not (Test-Path -LiteralPath $ResolvedBackup -PathType Leaf)) {
    throw "Restore drill accepts only an existing .dump directly inside backend/backups."
}
$ChecksumPath = "$ResolvedBackup.sha256"
if (-not (Test-Path -LiteralPath $ChecksumPath -PathType Leaf)) { throw "Backup checksum companion is missing." }
$ExpectedDigest = ((Get-Content -LiteralPath $ChecksumPath -Raw).Trim() -split '\s+')[0].ToLowerInvariant()
$ActualDigest = (Get-FileHash -LiteralPath $ResolvedBackup -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ExpectedDigest -notmatch '^[a-f0-9]{64}$' -or $ExpectedDigest -ne $ActualDigest) { throw "Backup checksum validation failed." }

$Docker = Get-Command docker -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
if ([string]::IsNullOrWhiteSpace($Docker)) {
    $Candidate = Join-Path $env:LOCALAPPDATA "Programs\DockerDesktop\resources\bin\docker.exe"
    if (Test-Path -LiteralPath $Candidate) { $Docker = $Candidate }
}
if ([string]::IsNullOrWhiteSpace($Docker)) { throw "Docker CLI is required for the restore drill." }
$DockerBin = Split-Path -Parent $Docker
$env:PATH = "$DockerBin;$env:PATH"

$RunId = [Guid]::NewGuid().ToString("N").Substring(0, 16)
$ContainerName = "cg-restore-drill-$RunId"
$VolumeName = "cg_restore_drill_$RunId"
if ($ContainerName -notmatch '^cg-restore-drill-[a-f0-9]{16}$' -or $VolumeName -notmatch '^cg_restore_drill_[a-f0-9]{16}$') { throw "Unsafe restore-drill resource identity." }
$PasswordBytes = [byte[]]::new(24)
[System.Security.Cryptography.RandomNumberGenerator]::Fill($PasswordBytes)
$DrillPassword = [Convert]::ToHexString($PasswordBytes).ToLowerInvariant()

try {
    & $Docker volume create $VolumeName | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Could not create isolated restore-drill volume." }
    $Mount = "$($ResolvedBackup.Replace('\', '/')):/restore/input.dump:ro"
    & $Docker run -d --name $ContainerName -e "POSTGRES_PASSWORD=$DrillPassword" -v "${VolumeName}:/var/lib/postgresql/data" -v $Mount postgres:16.8-alpine | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Could not start isolated restore-drill database." }
    $Ready = $false
    for ($Attempt = 0; $Attempt -lt 30; $Attempt += 1) {
        & $Docker exec $ContainerName pg_isready -U postgres -d postgres 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $Ready = $true; break }
        Start-Sleep -Milliseconds 500
    }
    if (-not $Ready) { throw "Isolated restore-drill database did not become ready." }
    & $Docker exec $ContainerName createdb -U postgres restore_drill
    if ($LASTEXITCODE -ne 0) { throw "Could not create isolated restore target." }
    & $Docker exec $ContainerName pg_restore -U postgres -d restore_drill --exit-on-error /restore/input.dump
    if ($LASTEXITCODE -ne 0) { throw "Backup failed a complete isolated restore." }
    $TableCountText = (& $Docker exec $ContainerName psql -U postgres -d restore_drill -Atc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';").Trim()
    $TableCount = 0
    if (-not [int]::TryParse($TableCountText, [ref]$TableCount) -or $TableCount -lt 10) { throw "Restored Nakama schema is incomplete." }
    Write-Host "PASS: backup checksum and complete isolated PostgreSQL restore succeeded ($TableCount public tables)."
} finally {
    & $Docker rm -f $ContainerName 2>$null | Out-Null
    & $Docker volume rm $VolumeName 2>$null | Out-Null
}
