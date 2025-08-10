#Requires -Version 5.1
$esc   = [char]27
$Cyan  = "${esc}[36m"
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Blue  = "${esc}[34m"
$Reset = "${esc}[0m"

$ErrorActionPreference = 'Stop'

function Assert-Administrator {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Error "This script must be run as Administrator. Please re-run PowerShell as Administrator and try again."
        exit 1
    }
}

function Ensure-WindowsUpdateServices {
    $requiredServices = @('wuauserv', 'bits', 'UsoSvc')
    foreach ($serviceName in $requiredServices) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($null -ne $service -and $service.Status -ne 'Running') {
                Start-Service -Name $serviceName -ErrorAction SilentlyContinue
            }
        }
        catch {
            # Non-fatal; continue
        }
    }
}

function Ensure-MicrosoftUpdateRegistered {
    try {
        $muServiceId = '7971f918-a847-4430-9279-4a52d1efe18d'
        $isRegistered = Get-WUServiceManager -ErrorAction SilentlyContinue |
            Where-Object { $_.ServiceID -eq $muServiceId }
        if (-not $isRegistered) {
            Write-Host "${Yellow}Registering Microsoft Update service...${Reset}"
            Add-WUServiceManager -MicrosoftUpdate -ErrorAction Stop | Out-Null
            Write-Host "${Green}Microsoft Update service registered.${Reset}"
        }
    }
    catch {
        Write-Host "${Yellow}Could not register Microsoft Update service (continuing): $($_.Exception.Message)${Reset}"
    }
}

function Install-NuGetProvider {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
        Write-Host "${Yellow}NuGet provider not found. Installing NuGet provider...${Reset}"
        try {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
            Write-Host "${Green}NuGet provider installed successfully!${Reset}"
        }
        catch {
            Write-Error "Failed to install NuGet provider. Please check your internet connection or try again later."
            exit 1
        }
    }
    else {
        Write-Host "${Blue}NuGet provider is already installed.${Reset}"
    }
}

function Install-PSWindowsUpdateModule {
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Host "${Yellow}Installing PSWindowsUpdate module...${Reset}"
        try {
            Install-Module -Name PSWindowsUpdate -Force -SkipPublisherCheck
            Write-Host "${Green}PSWindowsUpdate module installed successfully!${Reset}"
        }
        catch {
            Write-Error "Failed to install PSWindowsUpdate module. Please check your internet connection or try again later."
            exit 1
        }
    }
    else {
        Write-Host "${Blue}PSWindowsUpdate module is already installed.${Reset}"
    }
}

function Import-PSWindowsUpdateModule {
    Write-Host "${Cyan}Importing PSWindowsUpdate module...${Reset}"
    try {
        Import-Module PSWindowsUpdate -Force
    }
    catch {
        Write-Error "Failed to import PSWindowsUpdate module."
        exit 1
    }
}

function Update-Windows {
    Write-Host "${Cyan}`n=== Checking for available updates... ===${Reset}"
    try {
        # Query both Windows Update and Microsoft Update (if available) for completeness
        $updates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to check for Windows updates."
        exit 1
    }

    if ($updates) {
        Write-Host "${Yellow}`nThe following updates are available:${Reset}"
        $updates | Format-Table -AutoSize

        Write-Host "${Yellow}`nInstalling updates...${Reset}"
        try {
            # Use Get-WindowsUpdate with -Install for better reliability across PSWindowsUpdate versions
            Get-WindowsUpdate -MicrosoftUpdate -Install -AcceptAll -AutoReboot -ErrorAction Stop | Out-Null
            Write-Host "${Green}Updates installation process initiated!${Reset}"
        }
        catch {
            Write-Error "Failed to install updates."
            exit 1
        }
    }
    else {
        Write-Host "${Blue}No updates are available.${Reset}"
    }
}

function Get-InstalledUpdates {
    Write-Host "${Cyan}`n=== Recently installed updates ===${Reset}"
    try {
        Get-WUHistory | Format-Table -AutoSize
    }
    catch {
        Write-Error "Failed to retrieve update history."
    }
}

Assert-Administrator
Ensure-WindowsUpdateServices
Install-NuGetProvider
Install-PSWindowsUpdateModule
Import-PSWindowsUpdateModule
Ensure-MicrosoftUpdateRegistered
Update-Windows
Get-InstalledUpdates