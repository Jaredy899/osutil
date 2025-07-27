#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

function Install-NuGetProvider {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
        Write-Host "NuGet provider not found. Installing NuGet provider..." -ForegroundColor Yellow
        try {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
            Write-Host "NuGet provider installed successfully!" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install NuGet provider. Please check your internet connection or try again later."
            exit 1
        }
    }
    else {
        Write-Host "NuGet provider is already installed." -ForegroundColor Blue
    }
}

function Install-PSWindowsUpdateModule {
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Host "Installing PSWindowsUpdate module..." -ForegroundColor Yellow
        try {
            Install-Module -Name PSWindowsUpdate -Force -SkipPublisherCheck
            Write-Host "PSWindowsUpdate module installed successfully!" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install PSWindowsUpdate module. Please check your internet connection or try again later."
            exit 1
        }
    }
    else {
        Write-Host "PSWindowsUpdate module is already installed." -ForegroundColor Blue
    }
}

function Import-PSWindowsUpdateModule {
    Write-Host "Importing PSWindowsUpdate module..." -ForegroundColor Cyan
    try {
        Import-Module PSWindowsUpdate -Force
    }
    catch {
        Write-Error "Failed to import PSWindowsUpdate module."
        exit 1
    }
}

function Update-Windows {
    Write-Host "`n=== Checking for available updates... ===" -ForegroundColor Cyan
    try {
        $updates = Get-WindowsUpdate
    }
    catch {
        Write-Error "Failed to check for Windows updates."
        exit 1
    }

    if ($updates) {
        Write-Host "`nThe following updates are available:" -ForegroundColor Yellow
        $updates | Format-Table -AutoSize

        Write-Host "`nInstalling updates..." -ForegroundColor Yellow
        try {
            Install-WindowsUpdate -AcceptAll -AutoReboot
            Write-Host "Updates installation process initiated!" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install updates."
            exit 1
        }
    }
    else {
        Write-Host "No updates are available." -ForegroundColor Blue
    }
}

function Get-InstalledUpdates {
    Write-Host "`n=== Recently installed updates ===" -ForegroundColor Cyan
    try {
        Get-WUHistory | Format-Table -AutoSize
    }
    catch {
        Write-Error "Failed to retrieve update history."
    }
}

Install-NuGetProvider
Install-PSWindowsUpdateModule
Import-PSWindowsUpdateModule
Update-Windows
Get-InstalledUpdates