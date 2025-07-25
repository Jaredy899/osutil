#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../common-script.ps1"

function Update-System {
    Write-Host "Updating system packages..."
    try {
        winget upgrade --all --include-unknown
    }
    catch {
        Write-Error "Failed to update system packages. Please check your winget installation or try again later."
        exit 1
    }
    Write-Host "System update completed!"
}

Check-Env
Update-System