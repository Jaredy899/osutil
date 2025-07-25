#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../common-script.ps1"

function Install-Orbstack {
    if (-not (Get-ProgramInstalled -programName "orbstack")) {
        Write-Host "Installing Orbstack..."
        try {
            winget install -e --id Orbstack.Orbstack
        }
        catch {
            Write-Error "Failed to install Orbstack. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Orbstack is already installed."
    }
}

Check-Env
Install-Orbstack