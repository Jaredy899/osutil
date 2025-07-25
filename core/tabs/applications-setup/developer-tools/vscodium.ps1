#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../common-script.ps1"

function Install-VsCodium {
    if (-not (Get-ProgramInstalled -programName "vscodium")) {
        Write-Host "Installing VS Codium..."
        try {
            winget install -e --id VSCodium.VSCodium
        }
        catch {
            Write-Error "Failed to install VS Codium. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "VS Codium is already installed."
    }
}

Check-Env
Install-VsCodium