#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../common-script.ps1"

function Install-Applite {
    if (-not (Get-Command applite -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Applite..."
        try {
            winget install -e --id Applite.Applite
        }
        catch {
            Write-Error "Failed to install Applite. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Applite is already installed."
    }
}

Check-Env
Install-Applite