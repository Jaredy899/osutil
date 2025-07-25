#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../common-script.ps1"

function Fix-Finder {
    Write-Host "Applying global theme settings for Finder..."
    # Set the default Finder view to list view
    Write-Host "Setting default Finder view to list view..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Folder" -Value "f"
    # Show all filename extensions
    Write-Host "Showing all filename extensions in Finder..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
    # Show status bar in Finder
    Write-Host "Showing status bar in Finder..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "StatusBar" -Value 1
    # Show path bar in Finder
    Write-Host "Showing path bar in Finder..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "FullPath" -Value 1
    # Restart Finder to apply changes
    Write-Host "Finder has been restarted and settings have been applied."
    Stop-Process -Name "explorer" -Force
}

Check-Env
Fix-Finder