#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../common-script.ps1"

function Install-GithubDesktop {
    if (-not (Get-ProgramInstalled -programName "github")) {
        Write-Host "Installing Github Desktop..."
        try {
            winget install -e --id GitHub.GitHubDesktop
        }
        catch {
            Write-Error "Failed to install Github Desktop. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Github Desktop is already installed."
    }
}

Check-Env
Install-GithubDesktop