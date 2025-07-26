#Requires -Version 5.1

$ErrorActionPreference = 'Stop'



function Install-Raycast {
    if (-not (Get-Command raycast -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Raycast..."
        try {
            winget install -e --id Raycast.Raycast
        }
        catch {
            Write-Error "Failed to install Raycast. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Raycast is already installed."
    }
}


Install-Raycast
