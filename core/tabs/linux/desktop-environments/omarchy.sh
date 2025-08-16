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

# Check if the basecamp omarchy install script exists and fix potential issues
if [[ -f ~/.local/share/omarchy/install ]]; then
  echo -e "\nChecking basecamp omarchy install script for potential issues..."
  
  # Check if 'tte' command is used and fix it
  if grep -q "tte" ~/.local/share/omarchy/install; then
    echo -e "\nFixing 'tte' command issue in basecamp omarchy install script..."
    # Create a backup
    cp ~/.local/share/omarchy/install ~/.local/share/omarchy/install.backup
    
    # First, try to find tte in common locations
    TTE_FOUND=false
    for tte_path in "$HOME/.local/bin/tte" "/usr/local/bin/tte" "/usr/bin/tte" "$HOME/.cargo/bin/tte"; do
      if [[ -x "$tte_path" ]]; then
        echo -e "\nFound 'tte' at: $tte_path"
        # Create a symlink or add to PATH
        export PATH="$(dirname "$tte_path"):$PATH"
        TTE_FOUND=true
        break
      fi
    done
    
    # If tte not found, try to install it
    if [[ "$TTE_FOUND" == "false" ]]; then
      if command -v yay >/dev/null 2>&1; then
        echo -e "\nAttempting to install 'tte' from AUR..."
        yay -S --noconfirm tte 2>/dev/null && TTE_FOUND=true || {
          echo -e "\n'tte' not available in AUR, removing tte commands from install script..."
          # Remove or comment out tte commands
          sed -i 's/^[[:space:]]*tte/# tte/g' ~/.local/share/omarchy/install
          sed -i 's/[[:space:]]*tte/# tte/g' ~/.local/share/omarchy/install
        }
      else
        echo -e "\nNo AUR helper found, removing tte commands from install script..."
        # Remove or comment out tte commands
        sed -i 's/^[[:space:]]*tte/# tte/g' ~/.local/share/omarchy/install
        sed -i 's/[[:space:]]*tte/# tte/g' ~/.local/share/omarchy/install
      fi
    fi
    
    # If we found tte, make sure it's in the PATH for the install script
    if [[ "$TTE_FOUND" == "true" ]]; then
      echo -e "\nEnsuring 'tte' is available in PATH for installation..."
      # Add common tte locations to the beginning of the install script
      cat > ~/.local/share/omarchy/install.tmp << 'EOF'
#!/bin/bash

# Ensure tte is in PATH
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/bin:/usr/bin:$PATH"

EOF
      cat ~/.local/share/omarchy/install >> ~/.local/share/omarchy/install.tmp
      mv ~/.local/share/omarchy/install.tmp ~/.local/share/omarchy/install
      chmod +x ~/.local/share/omarchy/install
    fi
  fi
fi

echo -e "\nInstallation starting..."
source ~/.local/share/omarchy-titus/install.sh