#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../common-script.ps1"

function Install-Signal {
    if (-not (Get-ProgramInstalled -programName "signal")) {
        Write-Host "Installing Signal..."
        try {
            winget install -e --id Signal.Signal
        }
        catch {
            Write-Error "Failed to install Signal. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Signal is already installed."
    }
}

Check-Env
Install-Signal