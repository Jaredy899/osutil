#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../common-script.ps1"

function Clean-System {
    Write-Host "Performing Windows system cleanup..."
    # Clean temporary files
    Write-Host "Cleaning temporary files..."
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    # Clean system logs
    Write-Host "Cleaning system logs..."
    Get-EventLog -LogName * | ForEach-Object { Clear-EventLog -LogName $_.Log }
    # Clean DNS cache
    Write-Host "Flushing DNS cache..."
    Clear-DnsClientCache
    # Clean Windows Update cache
    Write-Host "Cleaning Windows Update cache..."
    Stop-Service -Name "wuauserv" -Force
    Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name "wuauserv"
    # Clean user cache
    Write-Host "Cleaning user cache..."
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCookies\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\History\*" -Recurse -Force -ErrorAction SilentlyContinue
    # Clean browser caches
    Write-Host "Cleaning browser caches..."
    Remove-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\*" -Recurse -Force -ErrorAction SilentlyContinue
    # Empty recycle bin
    Write-Host "Emptying recycle bin..."
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "System cleanup completed!"
}

Check-Env
Clean-System