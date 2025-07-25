#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../common-script.ps1"

function Install-Neovim {
    Write-Host "Setting up Neovim..."
    Write-Host "Installing Neovim and dependencies..."
    try {
        winget install -e --id Neovim.Neovim
        winget install -e --id BurntSushi.Ripgrep.MSVC
        winget install -e --id junegunn.fzf
    }
    catch {
        Write-Error "Failed to install Neovim and dependencies. Please check your winget installation or try again later."
        exit 1
    }
    if (Test-Path "$HOME/.config/nvim") {
        if (-not (Test-Path "$HOME/.config/nvim-backup")) {
            Write-Host "Backing up existing Neovim config..."
            Copy-Item -Path "$HOME/.config/nvim" -Destination "$HOME/.config/nvim-backup" -Recurse
        }
    }
    Remove-Item -Path "$HOME/.config/nvim" -Recurse -Force
    New-Item -Path "$HOME/.config/nvim" -ItemType Directory -Force
    Write-Host "Applying Titus Kickstart config..."
    git clone --depth 1 https://github.com/ChrisTitusTech/neovim.git /tmp/neovim
    Copy-Item -Path "/tmp/neovim/titus-kickstart/*" -Destination "$HOME/.config/nvim/" -Recurse
    Remove-Item -Path "/tmp/neovim" -Recurse -Force
    Write-Host "Neovim setup completed."
}

Check-Env
Install-Neovim