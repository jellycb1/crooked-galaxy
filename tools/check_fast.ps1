param(
    [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
& (Join-Path $PSScriptRoot "check_project.ps1") -GodotPath $GodotPath -Fast
