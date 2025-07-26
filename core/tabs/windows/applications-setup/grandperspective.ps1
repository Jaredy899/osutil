#Requires -Version 5.1

$ErrorActionPreference = 'Stop'



function Install-GrandPerspective {
    if (-not (Get-Command grandperspective -ErrorAction SilentlyContinue)) {
        Write-Host "Installing GrandPerspective..."
        try {
            winget install -e --id GrandPerspective.GrandPerspective
        }
        catch {
            Write-Error "Failed to install GrandPerspective. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "GrandPerspective is already installed."
    }
}


Install-GrandPerspective
