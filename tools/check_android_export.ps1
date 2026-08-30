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
$ExpectedCertificatePath = Join-Path $ProjectRoot "android\test-signing-cert.sha256"
$ProjectText = Get-Content -LiteralPath (Join-Path $ProjectRoot "project.godot") -Raw
$PresetText = Get-Content -LiteralPath (Join-Path $ProjectRoot "export_presets.cfg") -Raw

function Require-ConfigMatch {
    param([string]$Text, [string]$Pattern, [string]$Description)
    if (-not [regex]::IsMatch($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)) {
        throw "Android-first configuration drift: $Description."
    }
}

Require-ConfigMatch $ProjectText '^window/size/viewport_width=720$' "portrait viewport width must remain 720"
Require-ConfigMatch $ProjectText '^window/size/viewport_height=1280$' "portrait viewport height must remain 1280"
Require-ConfigMatch $ProjectText '^boot_splash/image="res://assets/boot_splash.png"$' "the original branded boot splash must remain configured"
Require-ConfigMatch $ProjectText '^config/quit_on_go_back=false$' "Android Back must remain delegated to the safe in-game router"
Require-ConfigMatch $ProjectText '^window/handheld/orientation=1$' "handheld orientation must remain portrait"
Require-ConfigMatch $ProjectText '^window/stretch/aspect="expand"$' "modern portrait screens must expand instead of letterboxing"
Require-ConfigMatch $ProjectText '^renderer/rendering_method.mobile="gl_compatibility"$' "mobile renderer must remain GL Compatibility"
Require-ConfigMatch $ProjectText '^textures/vram_compression/import_etc2_astc=true$' "mobile texture compression must remain enabled"
Require-ConfigMatch $PresetText '^architectures/armeabi-v7a=false$' "32-bit ARM must remain excluded from the compact APK"
Require-ConfigMatch $PresetText '^architectures/arm64-v8a=true$' "64-bit ARM must remain enabled"
Require-ConfigMatch $PresetText '^architectures/x86=false$' "x86 must remain excluded from the device APK"
Require-ConfigMatch $PresetText '^architectures/x86_64=false$' "x86-64 must remain excluded from the device APK"
Require-ConfigMatch $PresetText '^screen/immersive_mode=true$' "immersive mode must remain enabled"
Require-ConfigMatch $PresetText '^permissions/internet=true$' "the Android client must retain network access for staged online integration"
Require-ConfigMatch $PresetText '^custom_features=""$' "the Android APK must not enable reference placeholders"
Require-ConfigMatch $PresetText '^include_filter=""$' "the Android APK must not include staged reference files"

$ProjectVersion = [regex]::Match($ProjectText, 'config/version="([^"]+)"').Groups[1].Value
$AndroidVersion = [regex]::Match($PresetText, 'version/name="([^"]+)"').Groups[1].Value
$WindowsVersion = [regex]::Match($PresetText, 'application/product_version="([^"]+)"').Groups[1].Value
if ([string]::IsNullOrWhiteSpace($ProjectVersion) -or $ProjectVersion -ne $AndroidVersion -or $WindowsVersion -ne "$ProjectVersion.0") {
    throw "Project, Android, and Windows release versions are not synchronized."
}
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
$ApkSigner = Join-Path (Split-Path -Parent $Aapt2Candidates[0]) "apksigner.bat"
if (-not (Test-Path -LiteralPath $ApkSigner) -or -not (Test-Path -LiteralPath $ExpectedCertificatePath)) {
    throw "Android signature verifier or expected test-certificate fingerprint is missing."
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
if ($Badging -notmatch "uses-permission: name='android.permission.INTERNET'") {
    throw "Exported APK is missing android.permission.INTERNET."
}
$MinimumSdk = [regex]::Match($Badging, "(?:minSdkVersion|sdkVersion):'([0-9]+)'")
$TargetSdk = [regex]::Match($Badging, "targetSdkVersion:'([0-9]+)'")
$NativeCode = [regex]::Match($Badging, "native-code: ([^\r\n]+)")
if (-not $MinimumSdk.Success -or $MinimumSdk.Groups[1].Value -ne "24") {
    throw "Exported APK must retain Android 7.0 / API 24 compatibility."
}
if (-not $TargetSdk.Success -or [int]$TargetSdk.Groups[1].Value -lt 35) {
    throw "Exported APK target SDK unexpectedly regressed."
}
if (-not $NativeCode.Success -or $NativeCode.Groups[1].Value.Trim() -ne "'arm64-v8a'") {
    throw "Exported APK native code is not ARM64-only."
}

$StrictErrorPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$CertificateOutput = (& $ApkSigner verify --print-certs $OutputApk 2>&1) -join "`n"
$ApkSignerExitCode = $LASTEXITCODE
$ErrorActionPreference = $StrictErrorPreference
$CertificateMatch = [regex]::Match($CertificateOutput, 'Signer #1 certificate SHA-256 digest: ([0-9a-fA-F]{64})')
$ExpectedCertificate = (Get-Content -LiteralPath $ExpectedCertificatePath -Raw).Trim().ToLowerInvariant()
if ($ApkSignerExitCode -ne 0 -or -not $CertificateMatch.Success -or $CertificateMatch.Groups[1].Value.ToLowerInvariant() -ne $ExpectedCertificate) {
    throw "Exported APK signature does not match the update-compatible direct-test certificate."
}

& $GodotCandidates[0] --headless --path $ProjectRoot --export-pack "Android APK" $ContentPack --log-file (Join-Path $LogRoot "android_content_export.log")
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $ContentPack)) {
    throw "Could not produce the Android content-verification pack."
}
& $GodotCandidates[0] --headless --path (Join-Path $ProjectRoot "tools\export_pack_inspector") --log-file (Join-Path $LogRoot "android_pack_inspector.log") --script res://inspect_pack.gd -- $ContentPack
if ($LASTEXITCODE -ne 0) {
    throw "Android export is missing production art or contains forbidden reference placeholders."
}

$ApkSizeMb = (Get-Item -LiteralPath $OutputApk).Length / 1MB
if ($ApkSizeMb -gt 55.0) {
    throw ("Android APK exceeds the 55 MB direct-test budget ({0:N2} MB)." -f $ApkSizeMb)
}
Write-Host ("PASS: reference-free Android APK exported with original production art ({0:N2} MB, {1} v{2} code {3}, API 24+, ARM64, stable test signature)." -f $ApkSizeMb, $ExpectedPackage, $ExpectedVersionName, $ExpectedVersionCode)
