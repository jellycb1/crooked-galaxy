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

$ApkSizeMb = (Get-Item -LiteralPath $OutputApk).Length / 1MB
Write-Host ("PASS: installable Android APK exported ({0:N2} MB)." -f $ApkSizeMb)
