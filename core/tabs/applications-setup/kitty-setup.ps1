#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../common-script.ps1"

function Install-Kitty {
    if (-not (Get-Command kitty -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Kitty..."
        try {
            winget install -e --id KovidGoyal.Kitty
        }
        catch {
            Write-Error "Failed to install Kitty. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Kitty is already installed."
    }
}

function Setup-KittyConfig {
    Write-Host "Copying Kitty config files..."
    $configPath = "$HOME/.config/kitty"
    if (Test-Path $configPath) {
        if (-not (Test-Path "$configPath-bak")) {
            Copy-Item -Path $configPath -Destination "$configPath-bak" -Recurse
        }
    }
    else {
        New-Item -Path $configPath -ItemType Directory -Force
    }
    Invoke-WebRequest -Uri "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/kitty.conf" -OutFile "$configPath/kitty.conf"
    Invoke-WebRequest -Uri "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/nord.conf" -OutFile "$configPath/nord.conf"
}

Check-Env
Install-Kitty
Setup-KittyConfig