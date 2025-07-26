#Requires -Version 5.1

$ErrorActionPreference = 'Stop'



function Install-Alacritty {
    if (-not (Get-Command alacritty -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Alacritty..."
        try {
            winget install -e --id Alacritty.Alacritty
        }
        catch {
            Write-Error "Failed to install Alacritty. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Alacritty is already installed."
    }
}

function Setup-AlacrittyConfig {
    Write-Host "Copying alacritty config files..."
    $configPath = "$HOME/.config/alacritty"
    if (Test-Path $configPath) {
        if (-not (Test-Path "$configPath-bak")) {
            Copy-Item -Path $configPath -Destination "$configPath-bak" -Recurse
        }
    }
    else {
        New-Item -Path $configPath -ItemType Directory -Force
    }
    Invoke-WebRequest -Uri "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/alacritty.toml" -OutFile "$configPath/alacritty.toml"
    Invoke-WebRequest -Uri "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/keybinds.toml" -OutFile "$configPath/keybinds.toml"
    Invoke-WebRequest -Uri "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/nordic.toml" -OutFile "$configPath/nordic.toml"
    Write-Host "Alacritty configuration files copied."
}


Install-Alacritty
Setup-AlacrittyConfig
