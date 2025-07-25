#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../common-script.ps1"

function Install-Zoom {
    if (-not (Get-ProgramInstalled -programName "zoom")) {
        Write-Host "Installing Zoom..."
        try {
            winget install -e --id Zoom.Zoom
        }
        catch {
            Write-Error "Failed to install Zoom. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Zoom is already installed."
    }
}

Check-Env
Install-Zoom