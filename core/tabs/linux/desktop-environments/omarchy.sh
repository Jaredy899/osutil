#!/bin/bash

ansi_art='                 ▄▄▄                                                   
 ▄█████▄    ▄███████████▄    ▄███████   ▄███████   ▄███████   ▄█   █▄    ▄█   █▄ 
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   █▀   ███   ███  ███   ███
███   ███  ███   ███   ███ ▄███▄▄▄███ ▄███▄▄▄██▀  ███       ▄███▄▄▄███▄ ███▄▄▄███
███   ███  ███   ███   ███ ▀███▀▀▀███ ▀███▀▀▀▀    ███      ▀▀███▀▀▀███  ▀▀▀▀▀▀███
███   ███  ███   ███   ███  ███   ███ ██████████  ███   █▄   ███   ███  ▄██   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
 ▀█████▀    ▀█   ███   █▀   ███   █▀   ███   ███  ███████▀   ███   █▀    ▀█████▀ 
                                       ███   █▀                                  '

clear
echo -e "\n$ansi_art\n"

# Ensure we have a proper PATH for osutil environment
export PATH="$HOME/.local/bin:$HOME/.local/share/flatpak/exports/bin:/var/lib/flatpak/exports/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

sudo pacman -Sy --noconfirm --needed git

# Use custom repo if specified, otherwise default to basecamp/omarchy
OMARCHY_REPO="${OMARCHY_REPO:-basecamp/omarchy}"
TITUS_REPO="${TITUS_REPO:-christitustech/omarchy-titus}"

echo -e "\nCloning Omarchy from: https://github.com/${OMARCHY_REPO}.git"
rm -rf ~/.local/share/omarchy/
git clone "https://github.com/${OMARCHY_REPO}.git" ~/.local/share/omarchy >/dev/null

echo -e "\nCloning Titus-Omarchy from: https://github.com/${TITUS_REPO}.git"
rm -rf ~/.local/share/omarchy-titus/
git clone "https://github.com/${TITUS_REPO}.git" ~/.local/share/omarchy-titus >/dev/null

# Use custom branch if instructed
if [[ -n "$OMARCHY_REF" ]]; then
  echo -e "\eUsing branch: $OMARCHY_REF"
  cd ~/.local/share/omarchy
  git fetch origin "${OMARCHY_REF}" && git checkout "${OMARCHY_REF}"
  cd -
fi

# Fix tte command issues in both install scripts
echo -e "\nPreparing install scripts for osutil environment..."

# Fix basecamp omarchy install script
if [[ -f ~/.local/share/omarchy/install ]]; then
  # Create a backup
  cp ~/.local/share/omarchy/install ~/.local/share/omarchy/install.backup
  
  # Comment out all tte commands to avoid the error
  sed -i 's/^[[:space:]]*tte/# tte/g' ~/.local/share/omarchy/install
  sed -i 's/[[:space:]]*tte/# tte/g' ~/.local/share/omarchy/install
fi

# Fix Titus install script
if [[ -f ~/.local/share/omarchy-titus/install.sh ]]; then
  # Create a backup
  cp ~/.local/share/omarchy-titus/install.sh ~/.local/share/omarchy-titus/install.sh.backup
  
  # Comment out all tte commands to avoid the error
  sed -i 's/^[[:space:]]*tte/# tte/g' ~/.local/share/omarchy-titus/install.sh
  sed -i 's/[[:space:]]*tte/# tte/g' ~/.local/share/omarchy-titus/install.sh
fi

echo -e "\n'tte' commands have been commented out to ensure compatibility with osutil environment."

echo -e "\nInstallation starting..."
source ~/.local/share/omarchy-titus/install.sh