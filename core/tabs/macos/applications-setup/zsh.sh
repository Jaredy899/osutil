#!/bin/sh

. ../common-script.sh

# Centralized dotfiles repository
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Jaredy899/dotfiles.git}"
DOTFILES_DIR="$HOME/.local/share/dotfiles"

cloneDotfiles() {
    printf "%b\n" "${YELLOW}Cloning dotfiles repository...${RC}"

    # Ensure the parent directory exists
    mkdir -p "$HOME/.local/share"

    if [ -d "$DOTFILES_DIR" ]; then
        printf "%b\n" "${CYAN}Dotfiles directory already exists. Pulling latest changes...${RC}"
        if ! (cd "$DOTFILES_DIR" && git pull); then
            printf "%b\n" "${RED}Failed to update dotfiles repository${RC}"
            exit 1
        fi
    else
        if ! git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
            printf "%b\n" "${RED}Failed to clone dotfiles repository${RC}"
            exit 1
        fi
    fi

    printf "%b\n" "${GREEN}Dotfiles repository ready!${RC}"
}

backupZshConfig() {
    printf "%b\n" "${YELLOW}Backing up existing Zsh configuration...${RC}"

    # Backup existing .zshrc if it exists (skip if it's already a symlink)
    if [ -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.zshrc-backup" ] && [ ! -L "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc-backup"
        printf "%b\n" "${GREEN}Existing .zshrc backed up to .zshrc-backup.${RC}"
    fi

    # Backup existing .config/zsh if it exists (skip if it's already a symlink)
    if [ -d "$HOME/.config/zsh" ] && [ ! -d "$HOME/.config/zsh-backup" ] && [ ! -L "$HOME/.config/zsh" ]; then
        cp -r "$HOME/.config/zsh" "$HOME/.config/zsh-backup"
        printf "%b\n" "${GREEN}Existing Zsh config backed up to .config/zsh-backup.${RC}"
    fi

    # Backup existing starship config if it exists (skip if it's already a symlink)
    if [ -f "$HOME/.config/starship.toml" ] && [ ! -f "$HOME/.config/starship.toml.bak" ] && [ ! -L "$HOME/.config/starship.toml" ]; then
        cp "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak"
        printf "%b\n" "${GREEN}Existing starship config backed up to .config/starship.toml.bak${RC}"
    fi

    # Backup existing fastfetch config if it exists (skip if it's already a symlink)
    if [ -d "$HOME/.config/fastfetch" ] && [ ! -d "$HOME/.config/fastfetch-bak" ] && [ ! -L "$HOME/.config/fastfetch" ]; then
        cp -r "$HOME/.config/fastfetch" "$HOME/.config/fastfetch-bak"
        printf "%b\n" "${GREEN}Existing fastfetch config backed up to .config/fastfetch-bak${RC}"
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

installMise() {
    if command_exists mise; then
        printf "%b\n" "${GREEN}Mise already installed${RC}"
        return
    fi

    printf "%b\n" "${CYAN}Installing mise...${RC}"
    if ! curl -sSL https://mise.run | sh; then
        printf "%b\n" "${RED}Failed to install mise${RC}"
        exit 1
    else
        printf "%b\n" "${GREEN}Mise installed successfully!${RC}"
        printf "%b\n" "${YELLOW}Please restart your shell to see the changes.${RC}"
    fi
}

setupStarshipConfig() {
  printf "%b\n" "${YELLOW}Setting up Starship configuration...${RC}"

  # Symlink starship.toml from dotfiles repo
  if [ -f "$DOTFILES_DIR/config/starship.toml" ]; then
    mkdir -p "$HOME/.config"
    if [ -L "$HOME/.config/starship.toml" ] || [ -f "$HOME/.config/starship.toml" ]; then
      rm -f "$HOME/.config/starship.toml"
    fi
    ln -sf "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"
    printf "%b\n" "${GREEN}Starship configuration symlinked successfully.${RC}"
  else
    printf "%b\n" "${YELLOW}Starship config not found in dotfiles repo, skipping...${RC}"
  fi
}

setupFastfetchConfig() {
    printf "%b\n" "${YELLOW}Setting up Fastfetch configuration...${RC}"

    # Symlink fastfetch config from dotfiles repo
    if [ -f "$DOTFILES_DIR/config/fastfetch/macos.jsonc" ]; then
        mkdir -p "$HOME/.config/fastfetch"
        if [ -L "$HOME/.config/fastfetch/config.jsonc" ] || [ -f "$HOME/.config/fastfetch/config.jsonc" ]; then
            rm -f "$HOME/.config/fastfetch/config.jsonc"
        fi
        ln -sf "$DOTFILES_DIR/config/fastfetch/macos.jsonc" "$HOME/.config/fastfetch/config.jsonc"
        printf "%b\n" "${GREEN}Fastfetch configuration symlinked successfully.${RC}"
    else
        printf "%b\n" "${YELLOW}Fastfetch config not found in dotfiles repo, skipping...${RC}"
    fi
}

setupMiseConfig() {
    printf "%b\n" "${YELLOW}Setting up Mise configuration...${RC}"

    # Symlink mise config from dotfiles repo
    if [ -f "$DOTFILES_DIR/config/mise/config.toml" ]; then
        mkdir -p "$HOME/.config/mise"
        if [ -L "$HOME/.config/mise/config.toml" ] || [ -f "$HOME/.config/mise/config.toml" ]; then
            rm -f "$HOME/.config/mise/config.toml"
        fi
        ln -sf "$DOTFILES_DIR/config/mise/config.toml" "$HOME/.config/mise/config.toml"
        printf "%b\n" "${GREEN}Mise configuration symlinked successfully.${RC}"
    else
        printf "%b\n" "${YELLOW}Mise config not found in dotfiles repo, skipping...${RC}"
    fi
}

# Function to setup zsh configuration
setupZshConfig() {
  printf "%b\n" "${YELLOW}Setting up Zsh configuration...${RC}"

  # Symlink .zshrc from dotfiles repo
  if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
    if [ -L "$HOME/.zshrc" ] || [ -f "$HOME/.zshrc" ]; then
      rm -f "$HOME/.zshrc"
    fi
    ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
    printf "%b\n" "${GREEN}Zsh configuration symlinked successfully. Restart Shell.${RC}"
  else
    printf "%b\n" "${YELLOW}.zshrc not found in dotfiles repo, skipping...${RC}"
  fi
}

checkEnv
cloneDotfiles
backupZshConfig
installZshDepend
installMise
setupStarshipConfig
setupFastfetchConfig
setupMiseConfig
setupZshConfig
