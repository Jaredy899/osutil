#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../common-script.ps1"

function Install-Zed {
    if (-not (Get-ProgramInstalled -programName "zed")) {
        Write-Host "Installing Zed..."
        try {
            winget install -e --id Zed.Zed
        }
        catch {
            Write-Error "Failed to install Zed. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Zed is already installed."
    }
}

Check-Env
Install-Zed