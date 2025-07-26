#Requires -Version 5.1

$ErrorActionPreference = 'Stop'



function Install-Slack {
    if (-not (Get-ProgramInstalled -programName "slack")) {
        Write-Host "Installing Slack..."
        try {
            winget install -e --id Slack.Slack
        }
        catch {
            Write-Error "Failed to install Slack. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Slack is already installed."
    }
}


Install-Slack
