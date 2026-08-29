$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$BackendRoot = $PSScriptRoot
$EnvironmentPath = Join-Path $BackendRoot ".env"

function New-LocalSecret {
    $Bytes = [byte[]]::new(32)
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($Bytes)
    return [Convert]::ToHexString($Bytes).ToLowerInvariant()
}

$RequiredKeys = @(
    "CG_POSTGRES_PASSWORD",
    "CG_NAKAMA_SERVER_KEY",
    "CG_NAKAMA_SESSION_KEY",
    "CG_NAKAMA_REFRESH_KEY",
    "CG_NAKAMA_RUNTIME_HTTP_KEY",
    "CG_NAKAMA_CONSOLE_PASSWORD",
    "CG_NAKAMA_CONSOLE_SIGNING_KEY"
)
$Lines = @()
if (Test-Path -LiteralPath $EnvironmentPath -PathType Leaf) {
    $Lines = @(Get-Content -LiteralPath $EnvironmentPath)
}
$ExistingKeys = @{}
foreach ($Line in $Lines) {
    if ($Line -match '^([^#=]+)=.+$') {
        $ExistingKeys[$Matches[1]] = $true
    }
}
$Added = 0
foreach ($Key in $RequiredKeys) {
    if (-not $ExistingKeys.ContainsKey($Key)) {
        $Lines += "$Key=$(New-LocalSecret)"
        $Added += 1
    }
}
if ($Added -gt 0) {
    [System.IO.File]::WriteAllLines($EnvironmentPath, $Lines, [System.Text.UTF8Encoding]::new($false))
}
Write-Host "PASS: local-only backend credentials are complete; existing values were preserved ($Added added)."
