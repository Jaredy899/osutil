#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../common-script.ps1"

function Install-Depend {
    $dependencies = @(
        "tree",
        "multitail",
        "tealdeer",
        "unzip",
        "cmake",
        "make",
        "jq",
        "fd",
        "ripgrep",
        "automake",
        "autoconf",
        "rustup",
        "python",
        "pipx"
    )
    Write-Host "Installing development dependencies..."
    foreach ($package in $dependencies) {
        if (-not (Get-Command $package -ErrorAction SilentlyContinue)) {
            Write-Host "Installing $package..."
            try {
                winget install -e --id $package
            }
            catch {
                Write-Error "Failed to install $package. Please check your winget installation or try again later."
                exit 1
            }
        }
        else {
            Write-Host "$package is already installed."
        }
    }
    Write-Host "Development setup complete!"
}

Check-Env
Install-Depend