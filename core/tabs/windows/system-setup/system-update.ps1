# System Update Script for Windows
Write-Host "Updating Windows system..." -ForegroundColor Green

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Please run as administrator." -ForegroundColor Red
    exit 1
}

# Update Windows
Write-Host "Checking for Windows updates..." -ForegroundColor Blue
try {
    $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -Install
    if ($updates) {
        Write-Host "Windows updates installed successfully!" -ForegroundColor Green
    } else {
        Write-Host "No Windows updates available." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to check for Windows updates: $($_.Exception.Message)" -ForegroundColor Red
}

# Update Chocolatey packages if available
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "Updating Chocolatey packages..." -ForegroundColor Blue
    try {
        choco upgrade all -y
        Write-Host "Chocolatey packages updated successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Failed to update Chocolatey packages: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Update Winget packages if available
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Updating Winget packages..." -ForegroundColor Blue
    try {
        winget upgrade --all
        Write-Host "Winget packages updated successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Failed to update Winget packages: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "System update completed!" -ForegroundColor Green
