#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../common-script.ps1"

function Install-Onyx {
    if (-not (Get-Command onyx -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Onyx..."
        try {
            winget install -e --id TitaniumSoftware.Onyx
        }
        catch {
            Write-Error "Failed to install Onyx. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Onyx is already installed."
    }
}

Check-Env
Install-Onyx