#Requires -Version 5.1

$ErrorActionPreference = 'Stop'



function Install-Thunderbird {
    if (-not (Get-ProgramInstalled -programName "thunderbird")) {
        Write-Host "Installing Thunderbird..."
        try {
            winget install -e --id Mozilla.Thunderbird
        }
        catch {
            Write-Error "Failed to install Thunderbird. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Thunderbird is already installed."
    }
}


Install-Thunderbird
