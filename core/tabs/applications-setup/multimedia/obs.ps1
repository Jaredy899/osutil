#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../common-script.ps1"

function Install-OBS {
    if (-not (Get-ProgramInstalled -programName "obs")) {
        Write-Host "Installing OBS..."
        try {
            winget install -e --id OBSProject.OBSStudio
        }
        catch {
            Write-Error "Failed to install OBS. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "OBS is already installed."
    }
}

Check-Env
Install-OBS