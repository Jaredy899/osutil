#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../common-script.ps1"

function Install-VLC {
    if (-not (Get-ProgramInstalled -programName "vlc")) {
        Write-Host "Installing VLC..."
        try {
            winget install -e --id VideoLAN.VLC
        }
        catch {
            Write-Error "Failed to install VLC. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "VLC is already installed."
    }
}

Check-Env
Install-VLC