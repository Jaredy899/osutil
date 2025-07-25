#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../common-script.ps1"

function Configure-Trackpad {
    Write-Host "Configuring trackpad settings..."
    # This is not a direct equivalent of the macOS functionality, but it is the closest thing.
    # This will enable tap to click.
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force
    }
    Set-ItemProperty -Path $regPath -Name "EnableTapToClick" -Value 1
    Write-Host "Trackpad settings updated successfully."
}

Check-Env
Configure-Trackpad