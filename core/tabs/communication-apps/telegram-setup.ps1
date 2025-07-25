#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../common-script.ps1"

function Install-Telegram {
    if (-not (Get-ProgramInstalled -programName "telegram")) {
        Write-Host "Installing Telegram..."
        try {
            winget install -e --id Telegram.TelegramDesktop
        }
        catch {
            Write-Error "Failed to install Telegram. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Telegram is already installed."
    }
}

Check-Env
Install-Telegram