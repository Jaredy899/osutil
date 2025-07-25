#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../common-script.ps1"

function Backup-ZshConfig {
    Write-Host "Backing up existing Zsh configuration..."
    if (Test-Path "$HOME/.zshrc") {
        if (-not (Test-Path "$HOME/.zshrc-backup")) {
            Copy-Item -Path "$HOME/.zshrc" -Destination "$HOME/.zshrc-backup"
            Write-Host "Existing .zshrc backed up to .zshrc-backup."
        }
    }
    if (Test-Path "$HOME/.config/zsh") {
        if (-not (Test-Path "$HOME/.config/zsh-backup")) {
            Copy-Item -Path "$HOME/.config/zsh" -Destination "$HOME/.config/zsh-backup" -Recurse
            Write-Host "Existing Zsh config backed up to .config/zsh-backup."
        }
    }
}

function Install-ZshDepend {
    $dependencies = @(
        "zsh-autocomplete",
        "bat",
        "tree",
        "multitail",
        "fastfetch",
        "wget",
        "unzip",
        "fontconfig",
        "starship",
        "fzf",
        "zoxide"
    )
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
    $caskDependencies = @(
        "ghostty",
        "font-fira-code-nerd-font"
    )
    foreach ($cask in $caskDependencies) {
        if (-not (Get-Command $cask -ErrorAction SilentlyContinue)) {
            Write-Host "Installing $cask..."
            try {
                winget install -e --id $cask
            }
            catch {
                Write-Error "Failed to install $cask. Please check your winget installation or try again later."
                exit 1
            }
        }
        else {
            Write-Host "$cask is already installed."
        }
    }
    if (Test-Path "$HOME/.fzf/install") {
        & "$HOME/.fzf/install" --all
    }
}

function Setup-StarshipConfig {
    Write-Host "Setting up Starship configuration..."
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Jaredy899/mac/refs/heads/main/myzsh/starship.toml" -OutFile "$HOME/.config/starship.toml"
    Write-Host "Starship configuration has been set up successfully."
}

function Setup-FastfetchConfig {
    Write-Host "Copying Fastfetch config files..."
    $configPath = "$HOME/.config/fastfetch"
    if (Test-Path $configPath) {
        if (-not (Test-Path "$configPath-bak")) {
            Copy-Item -Path $configPath -Destination "$configPath-bak" -Recurse
        }
    }
    else {
        New-Item -Path $configPath -ItemType Directory -Force
    }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Jaredy899/mac/refs/heads/main/myzsh/config.jsonc" -OutFile "$configPath/config.jsonc"
}

function Setup-ZshConfig {
    Write-Host "Setting up Zsh configuration..."
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Jaredy899/mac/refs/heads/main/myzsh/.zshrc" -OutFile "$HOME/.zshrc"
    Write-Host "Zsh configuration has been set up successfully. Restart Shell."
}

Check-Env
Backup-ZshConfig
Install-ZshDepend
Setup-StarshipConfig
Setup-FastfetchConfig
Setup-ZshConfig