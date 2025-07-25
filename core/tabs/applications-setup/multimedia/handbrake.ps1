#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../common-script.ps1"

function Install-Handbrake {
    if (-not (Get-ProgramInstalled -programName "handbrake")) {
        Write-Host "Installing Handbrake..."
        try {
            winget install -e --id Handbrake.Handbrake
        }
        catch {
            Write-Error "Failed to install Handbrake. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Handbrake is already installed."
    }
}

Check-Env
Install-Handbrake