#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../common-script.ps1"

function Install-Iina {
    if (-not (Get-ProgramInstalled -programName "iina")) {
        Write-Host "Installing IINA..."
        try {
            winget install -e --id IINA.IINA
        }
        catch {
            Write-Error "Failed to install IINA. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "IINA is already installed."
    }
}

Check-Env
Install-Iina