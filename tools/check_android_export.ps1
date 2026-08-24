param(
    [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$GodotCandidates = @(@(
    $GodotPath,
    "C:\Tools\Godot\Godot_v4.7.1-stable_win64_console.exe",
    (Get-Command godot -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
    (Get-Command godot4 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) })

if ($GodotCandidates.Count -eq 0) {
    throw "Godot not found. Use -GodotPath with the installed console executable."
}

$BuildRoot = Join-Path $ProjectRoot "builds\android"
$OutputApk = Join-Path $BuildRoot "CrookedGalaxy.apk"
$LogRoot = Join-Path $ProjectRoot ".godot\export-logs"
$ContentPack = Join-Path $LogRoot "android_content_check.pck"
$DebugKey = Join-Path $ProjectRoot "android\crooked-galaxy-debug.keystore"
New-Item -ItemType Directory -Path $BuildRoot -Force | Out-Null
New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null

if (-not (Test-Path -LiteralPath $DebugKey)) {
    $Keytool = Join-Path $env:JAVA_HOME "bin\keytool.exe"
    if (-not (Test-Path -LiteralPath $Keytool)) {
        throw "Android test key is missing and keytool was not found under JAVA_HOME."
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $DebugKey) -Force | Out-Null
    & $Keytool -genkeypair -keystore $DebugKey -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Crooked Galaxy Test,O=Crooked Galaxy,C=PT"
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create the local Android test key."
    }
}

& $GodotCandidates[0] --headless --path $ProjectRoot --export-debug "Android APK" $OutputApk --log-file (Join-Path $LogRoot "android_export.log")
if ($LASTEXITCODE -ne 0) {
    throw "Android debug export failed with exit code $LASTEXITCODE."
}
if (-not (Test-Path -LiteralPath $OutputApk)) {
    throw "Android export did not produce CrookedGalaxy.apk."
}

$PresetText = Get-Content -LiteralPath (Join-Path $ProjectRoot "export_presets.cfg") -Raw
$ExpectedPackage = [regex]::Match($PresetText, 'package/unique_name="([^"]+)"').Groups[1].Value
$ExpectedVersionCode = [regex]::Match($PresetText, 'version/code=([0-9]+)').Groups[1].Value
$ExpectedVersionName = [regex]::Match($PresetText, 'version/name="([^"]+)"').Groups[1].Value
if ([string]::IsNullOrWhiteSpace($ExpectedPackage) -or [string]::IsNullOrWhiteSpace($ExpectedVersionCode) -or [string]::IsNullOrWhiteSpace($ExpectedVersionName)) {
    throw "Android package/version metadata is incomplete in export_presets.cfg."
}
$BuildToolsRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk\build-tools"
$Aapt2Candidates = @()
if (Test-Path -LiteralPath $BuildToolsRoot) {
    $Aapt2Candidates = @(Get-ChildItem -LiteralPath $BuildToolsRoot -Directory | Sort-Object Name -Descending | ForEach-Object { Join-Path $_.FullName "aapt2.exe" } | Where-Object { Test-Path -LiteralPath $_ })
}
if ($Aapt2Candidates.Count -eq 0) {
    throw "aapt2 was not found under the installed Android SDK build-tools."
}
$StrictErrorPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$Badging = (& $Aapt2Candidates[0] dump badging $OutputApk 2>&1) -join "`n"
$Aapt2ExitCode = $LASTEXITCODE
$ErrorActionPreference = $StrictErrorPreference
if ($Aapt2ExitCode -ne 0) {
    throw "Could not inspect the exported Android manifest."
}
$PackageMatch = [regex]::Match($Badging, "package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'")
if (-not $PackageMatch.Success) {
    throw "Could not parse package identity/version from the exported APK."
}
if ($PackageMatch.Groups[1].Value -ne $ExpectedPackage -or $PackageMatch.Groups[2].Value -ne $ExpectedVersionCode -or $PackageMatch.Groups[3].Value -ne $ExpectedVersionName) {
    throw "Exported APK metadata does not match export_presets.cfg."
}

& $GodotCandidates[0] --headless --path $ProjectRoot --export-pack "Android APK" $ContentPack --log-file (Join-Path $LogRoot "android_content_export.log")
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $ContentPack)) {
    throw "Could not produce the Android content-verification pack."
}
& $GodotCandidates[0] --headless --path (Join-Path $ProjectRoot "tools\export_pack_inspector") --log-file (Join-Path $LogRoot "android_pack_inspector.log") --script res://inspect_pack.gd -- $ContentPack
if ($LASTEXITCODE -ne 0) {
    throw "Android export contains forbidden reference placeholders."
}

$ApkSizeMb = (Get-Item -LiteralPath $OutputApk).Length / 1MB
if ($ApkSizeMb -gt 40.0) {
    throw ("Android APK exceeds the 40 MB direct-test budget ({0:N2} MB)." -f $ApkSizeMb)
}
Write-Host ("PASS: installable Android APK exported ({0:N2} MB, {1} v{2} code {3})." -f $ApkSizeMb, $ExpectedPackage, $ExpectedVersionName, $ExpectedVersionCode)
