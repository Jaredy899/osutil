#!/bin/bash

# Discord Setup Script for macOS
echo "Installing Discord..."

# Check if Discord is already installed
if [ -d "/Applications/Discord.app" ]; then
    echo "Discord is already installed. Launching..."
    open -a Discord
    exit 0
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Installing Homebrew first..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Discord using Homebrew
echo "Installing Discord using Homebrew..."
brew install --cask discord

if [ -d "/Applications/Discord.app" ]; then
    echo "Discord installed successfully!"
    open -a Discord
else
    echo "Failed to install Discord. Please install manually."
    exit 1
fi 