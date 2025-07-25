#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../common-script.ps1"

function Install-VsCode {
    if (-not (Get-ProgramInstalled -programName "code")) {
        Write-Host "Installing VS Code..."
        try {
            winget install -e --id Microsoft.VisualStudioCode
        }
        catch {
            Write-Error "Failed to install VS Code. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "VS Code is already installed."
    }
}

Check-Env
Install-VsCode