#!/bin/bash

# Discord Setup Script for Linux
echo "Installing Discord..."

# Detect package manager
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
elif command -v zypper &> /dev/null; then
    PKG_MANAGER="zypper"
else
    echo "Unsupported package manager. Please install Discord manually."
    exit 1
fi

# Check if Discord is already installed
if command -v discord &> /dev/null; then
    echo "Discord is already installed. Launching..."
    discord &
    exit 0
fi

# Install Discord based on package manager
case $PKG_MANAGER in
    "apt")
        echo "Installing Discord using apt..."
        wget -O - https://discord.com/api/downloads/distributions/app/stable/linux/x86_64 | tar -xzf -
        sudo mv Discord /opt/
        sudo ln -sf /opt/Discord/Discord /usr/local/bin/discord
        sudo cp /opt/Discord/discord.desktop /usr/share/applications/
        ;;
    "dnf")
        echo "Installing Discord using dnf..."
        sudo dnf install -y discord
        ;;
    "pacman")
        echo "Installing Discord using pacman..."
        sudo pacman -S --noconfirm discord
        ;;
    "zypper")
        echo "Installing Discord using zypper..."
        sudo zypper install -y discord
        ;;
esac

if command -v discord &> /dev/null; then
    echo "Discord installed successfully!"
    discord &
else
    echo "Failed to install Discord. Please install manually."
    exit 1
fi 