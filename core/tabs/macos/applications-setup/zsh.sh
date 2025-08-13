#!/bin/sh

. ../common-script.sh

backupZshConfig() {
    printf "%b\n" "${YELLOW}Backing up existing Zsh configuration...${RC}"
    
    # Backup existing .zshrc if it exists
    if [ -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.zshrc-backup" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc-backup"
        printf "%b\n" "${GREEN}Existing .zshrc backed up to .zshrc-backup.${RC}"
    fi
    
    # Backup existing .config/zsh if it exists
    if [ -d "$HOME/.config/zsh" ] && [ ! -d "$HOME/.config/zsh-backup" ]; then
        cp -r "$HOME/.config/zsh" "$HOME/.config/zsh-backup"
        printf "%b\n" "${GREEN}Existing Zsh config backed up to .config/zsh-backup.${RC}"
    fi
}

installZshDepend() {
    # List of dependencies
    DEPENDENCIES="zsh-autocomplete bat tree multitail fastfetch wget unzip fontconfig starship fzf zoxide"

    printf "%b\n" "${CYAN}Installing dependencies...${RC}"
    for package in $DEPENDENCIES; do
        if brewprogram_exists "$package"; then
            printf "%b\n" "${GREEN}$package is already installed, skipping...${RC}"
        else
            printf "%b\n" "${CYAN}Installing $package...${RC}"
            if ! brew install "$package"; then
                printf "%b\n" "${RED}Failed to install $package. Please check your brew installation.${RC}"
                exit 1
            fi
        fi
    done

    # List of cask dependencies
    CASK_DEPENDENCIES="ghostty font-fira-code-nerd-font"

    printf "%b\n" "${CYAN}Installing cask dependencies...${RC}"
    for cask in $CASK_DEPENDENCIES; do
        if brewprogram_exists "$cask"; then
            printf "%b\n" "${GREEN}$cask is already installed, skipping...${RC}"
        else
            printf "%b\n" "${CYAN}Installing $cask...${RC}"
            if ! brew install --cask "$cask"; then
                printf "%b\n" "${RED}Failed to install $cask. Please check your brew installation.${RC}"
                exit 1
            fi
        fi
    done

    if [ -e ~/.fzf/install ]; then
        if ! ~/.fzf/install --all; then
            printf "%b\n" "${RED}Failed to install fzf. Please check your brew installation.${RC}"
            exit 1
        fi
    fi
}

setupStarshipConfig() {
  printf "%b\n" "${YELLOW}Setting up Starship configuration...${RC}"
  
  wget https://raw.githubusercontent.com/Jaredy899/mac/refs/heads/main/myzsh/starship.toml -O "$HOME/.config/starship.toml"
  printf "%b\n" "${GREEN}Starship configuration has been set up successfully.${RC}"
}

setupFastfetchConfig() {
    printf "%b\n" "${YELLOW}Copying Fastfetch config files...${RC}"
    if [ -d "${HOME}/.config/fastfetch" ] && [ ! -d "${HOME}/.config/fastfetch-bak" ]; then
        cp -r "${HOME}/.config/fastfetch" "${HOME}/.config/fastfetch-bak"
    fi
    mkdir -p "${HOME}/.config/fastfetch/"
    curl -fsSLo "${HOME}/.config/fastfetch/config.jsonc" https://raw.githubusercontent.com/Jaredy899/mac/refs/heads/main/myzsh/config.jsonc
}

# Function to setup zsh configuration
setupZshConfig() {
  printf "%b\n" "${YELLOW}Setting up Zsh configuration...${RC}"

  wget https://raw.githubusercontent.com/Jaredy899/mac/refs/heads/main/myzsh/.zshrc -O "$HOME/.zshrc"

  # Ensure .zshrc is sourced
  if [ ! -f "$HOME/.zshrc" ]; then
    printf "%b\n" "${RED}Zsh configuration file not found!${RC}"
    exit 1
  fi
  
  printf "%b\n" "${GREEN}Zsh configuration has been set up successfully. Restart Shell.${RC}"
}

checkEnv
backupZshConfig
installZshDepend
setupStarshipConfig
setupFastfetchConfig
setupZshConfig
