#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../common-script.ps1"

function Install-CommanderOne {
    if (-not (Get-Command Commander-One -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Commander One..."
        try {
            winget install -e --id Eltima.CommanderOne
        }
        catch {
            Write-Error "Failed to install Commander One. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Commander One is already installed."
    }
}

Check-Env
Install-CommanderOne