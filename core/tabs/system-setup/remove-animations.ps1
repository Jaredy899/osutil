#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../common-script.ps1"

function Remove-Animations {
    Write-Host "Reducing motion and animations on Windows..."
    # Reduce motion in Accessibility settings (most effective)
    Write-Host "Setting reduce motion preference..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Animations" -Value 0
    # Disable window animations
    Write-Host "Disabling window animations..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 3
    Write-Host "Motion and animations have been reduced."
}

Check-Env
Remove-Animations