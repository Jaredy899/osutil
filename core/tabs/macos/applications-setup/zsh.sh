#!/bin/sh

. ../common-script.sh

# Centralized dotfiles repository
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Jaredy899/dotfiles.git}"
DOTFILES_DIR="$HOME/dotfiles"

cloneDotfiles() {
    printf "%b\n" "${YELLOW}Cloning dotfiles repository...${RC}"

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

backupExistingConfigs() {
    printf "%b\n" "${YELLOW}Backing up existing configuration files...${RC}"

    # Create backup directory
    BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    # Backup existing configs that might conflict with Stow
    for config in .zshrc .config/zsh .config/starship.toml .config/fastfetch .config/mise; do
        if [ -e "$HOME/$config" ] && [ ! -L "$HOME/$config" ]; then
            printf "%b\n" "${CYAN}Backing up $config...${RC}"
            cp -r "$HOME/$config" "$BACKUP_DIR/"
        fi
    done

    if [ -d "$BACKUP_DIR" ]; then
        printf "%b\n" "${GREEN}Existing configs backed up to $BACKUP_DIR${RC}"
    else
        printf "%b\n" "${GREEN}No existing configs to backup${RC}"
    fi
}

installZshDepend() {
    # List of dependencies
    DEPENDENCIES="stow zsh-autocomplete bat tree multitail fastfetch wget unzip fontconfig starship fzf zoxide"

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

    if [ -e "$HOME/.fzf/install" ]; then
        if ! "$HOME/.fzf/install" --all; then
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

setupDotfilesWithStow() {
    printf "%b\n" "${YELLOW}Setting up dotfiles with GNU Stow...${RC}"

    if [ ! -d "$DOTFILES_DIR" ]; then
        printf "%b\n" "${RED}Dotfiles directory not found at $DOTFILES_DIR${RC}"
        exit 1
    fi

    # Change to dotfiles directory and stow packages
    cd "$DOTFILES_DIR" && stow zsh config

    # Manual symlink for fastfetch config due to non-standard structure
    printf "%b\n" "${YELLOW}Setting up Fastfetch configuration...${RC}"
    mkdir -p "$HOME/.config/fastfetch"
    ln -sf "$DOTFILES_DIR/config/.config/fastfetch/macos.jsonc" "$HOME/.config/fastfetch/config.jsonc"

    printf "%b\n" "${GREEN}All dotfiles configured with Stow! Restart your shell to see changes.${RC}"
}

checkEnv
cloneDotfiles
backupExistingConfigs
installZshDepend
installMise
setupDotfilesWithStow
