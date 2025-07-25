#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../common-script.ps1"

function Install-DockerDesktop {
    if (-not (Get-ProgramInstalled -programName "docker")) {
        Write-Host "Installing Docker Desktop..."
        try {
            winget install -e --id Docker.DockerDesktop
        }
        catch {
            Write-Error "Failed to install Docker Desktop. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Docker Desktop is already installed."
    }
}

Check-Env
Install-DockerDesktop