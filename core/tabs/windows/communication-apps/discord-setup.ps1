#Requires -Version 5.1

$ErrorActionPreference = 'Stop'



function Install-Discord {
    if (-not (Get-ProgramInstalled -programName "discord")) {
        Write-Host "Installing Discord..."
        try {
            winget install -e --id Discord.Discord
        }
        catch {
            Write-Error "Failed to install Discord. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Discord is already installed."
    }
}


Install-Discord
