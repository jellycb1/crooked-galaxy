param(
    [string]$AdbPath = "",
    [string]$GodotPath = "",
    [string]$SshTarget = "cgdeploy@2.29.2.190",
    [string]$StagingHost = "staging-api.crookedgalaxy.com",
    [string]$Serial = "",
    [switch]$SkipBuild,
    [switch]$AllowEmulator,
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$PackageName = "com.crookedgalaxy.game"
$MailboxRelativePath = "files/crooked_galaxy_android_staging_probe.json"
$ApkPath = Join-Path $ProjectRoot "builds/android/CrookedGalaxy.apk"
$EvidenceRoot = Join-Path $ProjectRoot "artifacts/android-staging"

$AdbCandidates = @(@(
    $AdbPath,
    (Join-Path $env:LOCALAPPDATA "Android/Sdk/platform-tools/adb.exe"),
    (Get-Command adb -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) })
if ($AdbCandidates.Count -eq 0) { throw "adb was not found. Install Android SDK Platform-Tools or use -AdbPath." }
$Adb = $AdbCandidates[0]

if ($StagingHost -notmatch '^[a-z0-9.-]+$') { throw "Unsafe staging host." }
$ProbeSource = Get-Content -LiteralPath (Join-Path $ProjectRoot "scripts/staging_boot_probe.gd") -Raw
$StateSource = Get-Content -LiteralPath (Join-Path $ProjectRoot "scripts/game_state.gd") -Raw
$DeploymentSource = Get-Content -LiteralPath (Join-Path $ProjectRoot "scripts/backend_deployment_rules.gd") -Raw
foreach ($Guard in @(
    'ANDROID_STAGING_PROBE_PATH',
    'DirAccess.remove_absolute',
    'canonicalize_android_staging_probe'
)) {
    if (-not $ProbeSource.Contains($Guard) -and -not $DeploymentSource.Contains($Guard)) { throw "Android staging probe guard is missing: $Guard" }
}
if (-not $StateSource.Contains('BackendDeploymentRulesScript.staging_probe_requested()')) {
    throw "The physical probe could load or persist the tester's real save."
}
if ($DeploymentSource.Contains($StagingHost) -or $ProbeSource.Contains($StagingHost)) {
    throw "The staging host must not be embedded in the exported game."
}

if ($ValidateOnly) {
    Write-Host "PASS: Android staging harness, private one-use mailbox, save isolation, and adb discovery are ready."
    exit 0
}

if (-not $SkipBuild) {
    & (Join-Path $ProjectRoot "tools/check_android_export.ps1") -GodotPath $GodotPath
    if ($LASTEXITCODE -ne 0) { throw "Android export gate failed." }
}
if (-not (Test-Path -LiteralPath $ApkPath)) { throw "Validated APK not found at $ApkPath." }

$DeviceLines = @(& $Adb devices -l)
if ($LASTEXITCODE -ne 0) { throw "adb could not enumerate devices." }
$Devices = @($DeviceLines | Select-Object -Skip 1 | Where-Object { $_ -match '^([^\s]+)\s+device(?:\s|$)' } | ForEach-Object {
    [PSCustomObject]@{ Serial = $Matches[1]; Description = $_ }
})
if (-not [string]::IsNullOrWhiteSpace($Serial)) {
    $Devices = @($Devices | Where-Object { $_.Serial -eq $Serial })
}
if (-not $AllowEmulator) {
    $Devices = @($Devices | Where-Object { $_.Serial -notmatch '^emulator-' -and $_.Description -notmatch 'model:sdk_' })
}
if ($Devices.Count -ne 1) {
    throw "Connect and authorize exactly one physical Android device (found $($Devices.Count)). Use -Serial only when more than one is intentionally attached."
}
$Serial = $Devices[0].Serial

Write-Host "Installing the validated APK as an in-place update on $Serial (application data is preserved)..."
& $Adb -s $Serial install -r $ApkPath
if ($LASTEXITCODE -ne 0) { throw "APK update failed. The existing app data was not intentionally removed." }

$RunAsResult = (& $Adb -s $Serial shell run-as $PackageName pwd 2>&1) -join "`n"
if ($LASTEXITCODE -ne 0 -or $RunAsResult -match 'not debuggable|unknown package|Permission denied') {
    throw "The installed package does not permit the private debug mailbox: $RunAsResult"
}

$ClientKey = $null
$Payload = $null
$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
$EvidenceDirectory = Join-Path $EvidenceRoot $Timestamp
New-Item -ItemType Directory -Path $EvidenceDirectory -Force | Out-Null
try {
    $ClientKey = (& ssh $SshTarget "sed -n 's/^CG_NAKAMA_SERVER_KEY=//p' /opt/crooked-galaxy/backend/.env.staging").Trim()
    if ($LASTEXITCODE -ne 0 -or $ClientKey.Length -lt 16) {
        throw "Could not retrieve the staging client key through the protected operator path."
    }
    $DeviceId = "cg-android-$([Guid]::NewGuid().ToString('N'))"
    $Payload = @{
        schema = 1
        mode = "android_staging_probe_v1"
        host = $StagingHost
        client_key = $ClientKey
        device_id = $DeviceId
        expires_at_unix = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() + 300
    } | ConvertTo-Json -Compress

    $StartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $StartInfo.FileName = $Adb
    $StartInfo.UseShellExecute = $false
    $StartInfo.RedirectStandardInput = $true
    $StartInfo.RedirectStandardOutput = $true
    $StartInfo.RedirectStandardError = $true
    $MailboxWriteCommand = "'mkdir -p files; umask 077; cat > $MailboxRelativePath'"
    foreach ($Argument in @('-s', $Serial, 'shell', 'run-as', $PackageName, 'sh', '-c', $MailboxWriteCommand)) {
        [void]$StartInfo.ArgumentList.Add($Argument)
    }
    $Writer = [System.Diagnostics.Process]::new()
    $Writer.StartInfo = $StartInfo
    [void]$Writer.Start()
    $Writer.StandardInput.Write($Payload)
    $Writer.StandardInput.Close()
    $Writer.WaitForExit()
    $WriterError = $Writer.StandardError.ReadToEnd()
    if ($Writer.ExitCode -ne 0) { throw "Could not write the private probe mailbox: $WriterError" }

    & $Adb -s $Serial logcat -c
    & $Adb -s $Serial shell am force-stop $PackageName
    & $Adb -s $Serial shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1 *> $null
    if ($LASTEXITCODE -ne 0) { throw "Could not launch Crooked Galaxy on the device." }

    # A fresh staging hunter follows the real 147-second starter route. Leave
    # bounded room for Android cold start, TLS, reward mutations and reconnect.
    $Deadline = [DateTime]::UtcNow.AddSeconds(240)
    $ProbeLog = ""
    do {
        Start-Sleep -Milliseconds 750
        $ProbeLog = (& $Adb -s $Serial logcat -d -v threadtime 2>&1) -join "`n"
        if ($ProbeLog.Contains('FAIL: staging normal-boot probe:')) { break }
    } while (-not $ProbeLog.Contains('PASS: normal main-scene boot completed TLS staging') -and [DateTime]::UtcNow -lt $Deadline)

    if ($ProbeLog.Contains($ClientKey)) { throw "Credential appeared in Android logs; evidence was not written." }
    $ProbeLog | Set-Content -LiteralPath (Join-Path $EvidenceDirectory "logcat.txt") -Encoding utf8
    (& $Adb -s $Serial shell dumpsys package $PackageName 2>&1) -join "`n" | Set-Content -LiteralPath (Join-Path $EvidenceDirectory "package.txt") -Encoding utf8
    (& $Adb -s $Serial shell getprop 2>&1) -join "`n" | Select-String -Pattern '\[ro\.product|\[ro\.build\.version|\[ro\.hardware' | Set-Content -LiteralPath (Join-Path $EvidenceDirectory "device.txt") -Encoding utf8

    $MailboxCheckCommand = "'if test -e $MailboxRelativePath; then echo PRESENT; else echo ABSENT; fi'"
    $MailboxCheck = (& $Adb -s $Serial shell run-as $PackageName sh -c $MailboxCheckCommand 2>&1) -join "`n"
    if ($MailboxCheck -notmatch 'ABSENT') { throw "The one-use mailbox was not deleted before the network proof." }
    if ($ProbeLog.Contains('FAIL: staging normal-boot probe:')) { throw "Physical staging probe reported a failure. See $EvidenceDirectory/logcat.txt." }
    if (-not $ProbeLog.Contains('PASS: normal main-scene boot completed TLS staging')) { throw "Physical staging probe timed out. See $EvidenceDirectory/logcat.txt." }
    Write-Host "PASS: physical Android completed public TLS, archival cutover, authored hunt/reward/equipment, read-only cache, and reconnect."
    Write-Host "Evidence: $EvidenceDirectory"
} finally {
    & $Adb -s $Serial shell run-as $PackageName rm -f $MailboxRelativePath 2>$null | Out-Null
    $Payload = $null
    $ClientKey = $null
}
