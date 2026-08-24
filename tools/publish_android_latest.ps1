param(
    [string]$GodotPath = "",
    [string]$Repository = "jellycb1/crooked-galaxy"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ExportScript = Join-Path $PSScriptRoot "check_android_export.ps1"
$OutputApk = Join-Path $ProjectRoot "builds\android\CrookedGalaxy.apk"
$ChecksumPath = "$OutputApk.sha256"
$DownloadUrl = "https://github.com/$Repository/releases/download/latest/CrookedGalaxy.apk"
$ChecksumUrl = "$DownloadUrl.sha256"

$DirtyTrackedFiles = (& git -C $ProjectRoot status --porcelain --untracked-files=no) -join "`n"
if ($LASTEXITCODE -ne 0 -or -not [string]::IsNullOrWhiteSpace($DirtyTrackedFiles)) {
    throw "Refusing to publish: tracked project files must be committed first."
}

& $ExportScript -GodotPath $GodotPath
if ($LASTEXITCODE -ne 0) {
    throw "Android export validation failed with exit code $LASTEXITCODE."
}

& gh auth status --hostname github.com
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is not authenticated. Run gh auth login first."
}

$Commit = (& git -C $ProjectRoot rev-parse --short HEAD).Trim()
$ProjectText = Get-Content -LiteralPath (Join-Path $ProjectRoot "project.godot") -Raw
$VersionMatch = [regex]::Match($ProjectText, 'config/version="([^"]+)"')
if (-not $VersionMatch.Success) {
    throw "Could not resolve config/version from project.godot."
}
$Version = $VersionMatch.Groups[1].Value
$ApkHash = (Get-FileHash -LiteralPath $OutputApk -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath $ChecksumPath -Value "$ApkHash  CrookedGalaxy.apk" -Encoding ascii
$Notes = "Crooked Galaxy $Version Android test build from commit $Commit. ARM64, update-compatible debug signature for direct testing.`n`nSHA-256: ``$ApkHash``"

& gh release view latest --repo $Repository *> $null
if ($LASTEXITCODE -eq 0) {
	& gh release upload latest "$OutputApk#CrookedGalaxy.apk" "$ChecksumPath#CrookedGalaxy.apk.sha256" --repo $Repository --clobber
	if ($LASTEXITCODE -eq 0) {
		& gh release edit latest --repo $Repository --title "Latest Android build" --notes $Notes
	}
} else {
	& gh release create latest "$OutputApk#CrookedGalaxy.apk" "$ChecksumPath#CrookedGalaxy.apk.sha256" --repo $Repository --title "Latest Android build" --notes $Notes
}
if ($LASTEXITCODE -ne 0) {
	throw "Could not publish CrookedGalaxy.apk."
}

$ReleaseJson = (& gh api "repos/$Repository/releases/tags/latest") -join "`n"
if ($LASTEXITCODE -ne 0) {
	throw "Could not verify the published release."
}
$Release = $ReleaseJson | ConvertFrom-Json
$RemoteApk = @($Release.assets | Where-Object { $_.name -eq "CrookedGalaxy.apk" }) | Select-Object -First 1
$RemoteChecksum = @($Release.assets | Where-Object { $_.name -eq "CrookedGalaxy.apk.sha256" }) | Select-Object -First 1
if ($null -eq $RemoteApk -or $null -eq $RemoteChecksum -or [int64]$RemoteApk.size -ne (Get-Item -LiteralPath $OutputApk).Length) {
	throw "Published release assets are missing or the APK size differs from the validated local artifact."
}
if (-not [string]::IsNullOrWhiteSpace([string]$RemoteApk.digest) -and [string]$RemoteApk.digest -ne "sha256:$ApkHash") {
	throw "Published APK digest differs from the validated local artifact."
}

Write-Host "PASS: Android APK published and remotely verified at $DownloadUrl"
Write-Host "PASS: SHA-256 published at $ChecksumUrl ($ApkHash)"
