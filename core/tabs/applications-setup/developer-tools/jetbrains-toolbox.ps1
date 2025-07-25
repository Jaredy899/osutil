#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../common-script.ps1"

function Install-JetBrainsToolBox {
    if (-not (Get-ProgramInstalled -programName "jetbrains-toolbox")) {
        Write-Host "Installing Jetbrains Toolbox..."
        try {
            winget install -e --id JetBrains.Toolbox
        }
        catch {
            Write-Error "Failed to install Jetbrains Toolbox. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Jetbrains toolbox is already installed."
    }
}

Check-Env
Install-JetBrainsToolBox