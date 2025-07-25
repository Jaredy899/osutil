#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../common-script.ps1"

function Install-Sublime {
    if (-not (Get-ProgramInstalled -programName "sublime")) {
        Write-Host "Installing Sublime..."
        try {
            winget install -e --id SublimeHQ.SublimeText.4
        }
        catch {
            Write-Error "Failed to install Sublime. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Sublime is already installed."
    }
}

Check-Env
Install-Sublime