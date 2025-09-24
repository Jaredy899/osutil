#!/bin/sh

. ../common-script.sh

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
    BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    
    for config in .zshrc .config/zsh .config/starship.toml .config/fastfetch .config/mise; do
        if [ -e "$HOME/$config" ] && [ ! -L "$HOME/$config" ]; then
            mkdir -p "$BACKUP_DIR"
            cp -r "$HOME/$config" "$BACKUP_DIR/"
        fi
    done
}

installZshDepend() {
    DEPENDENCIES="stow zsh-autocomplete bat tree multitail fastfetch wget unzip fontconfig starship fzf zoxide mise"

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

    if ! brewprogram_exists ghostty; then
        printf "%b\n" "${CYAN}Installing ghostty...${RC}"
        if ! brew install --cask ghostty; then
            printf "%b\n" "${RED}Failed to install ghostty. Please check your brew installation.${RC}"
            exit 1
        fi
    fi

}


setupDotfilesWithStow() {
    printf "%b\n" "${YELLOW}Setting up dotfiles with GNU Stow...${RC}"

    if [ ! -d "$DOTFILES_DIR" ]; then
        printf "%b\n" "${RED}Dotfiles directory not found at $DOTFILES_DIR${RC}"
        exit 1
    fi

    mkdir -p "$HOME/.config"

    cd "$DOTFILES_DIR" && stow zsh config

    mkdir -p "$HOME/.config/fastfetch"
    ln -sf "$DOTFILES_DIR/config/.config/fastfetch/macos.jsonc" "$HOME/.config/fastfetch/config.jsonc"

    printf "%b\n" "${GREEN}All dotfiles configured with Stow! Restart your shell to see changes.${RC}"
}

checkEnv
cloneDotfiles
backupExistingConfigs
installZshDepend
setupDotfilesWithStow
