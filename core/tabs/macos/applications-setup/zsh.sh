#!/bin/sh

. ../common-script.sh

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Jaredy899/dotfiles.git}"
DOTFILES_DIR="$HOME/dotfiles"

cloneDotfiles() {
    printf "%b\n" "${YELLOW}Cloning dotfiles repository...${RC}"

    # Ensure git is available
    if ! command_exists git; then
        printf "%b\n" "${RED}Git is required but not installed. Please install git first.${RC}"
        exit 1
    fi

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
    
    for config in .zshrc .config/starship.toml .config/fastfetch .config/mise; do
        if [ -e "$HOME/$config" ] && [ ! -L "$HOME/$config" ]; then
            mkdir -p "$BACKUP_DIR"
            cp -r "$HOME/$config" "$BACKUP_DIR/"
        fi
    done
}

installZshDepend() {
    DEPENDENCIES="git zsh-autocomplete bat tree multitail fastfetch wget unzip fontconfig starship fzf zoxide mise eza"

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


symlinkConfigs() {
    printf "%b\n" "${YELLOW}Symlinking configuration files...${RC}"

    if [ ! -d "$DOTFILES_DIR" ]; then
        printf "%b\n" "${RED}Dotfiles directory not found at $DOTFILES_DIR${RC}"
        exit 1
    fi

    # Create necessary directories
    mkdir -p "$HOME/.config" "$HOME/.config/fastfetch" "$HOME/.config/mise"

    # Symlink zsh configuration
    if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
        if [ -L "$HOME/.zshrc" ] || [ -f "$HOME/.zshrc" ]; then
            rm -f "$HOME/.zshrc"
        fi
        ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
        printf "%b\n" "${GREEN}Symlinked .zshrc from dotfiles${RC}"
    else
        printf "%b\n" "${YELLOW}.zshrc not found in dotfiles repo, skipping...${RC}"
    fi

    # Symlink starship config
    if [ -f "$DOTFILES_DIR/config/starship.toml" ]; then
        if [ -L "$HOME/.config/starship.toml" ] || [ -f "$HOME/.config/starship.toml" ]; then
            rm -f "$HOME/.config/starship.toml"
        fi
        ln -sf "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"
        printf "%b\n" "${GREEN}Symlinked starship.toml from dotfiles${RC}"
    else
        printf "%b\n" "${YELLOW}starship.toml not found in dotfiles repo, skipping...${RC}"
    fi

    # Symlink fastfetch config for macOS
    if [ -f "$DOTFILES_DIR/config/fastfetch/macos.jsonc" ]; then
        if [ -L "$HOME/.config/fastfetch/config.jsonc" ] || [ -f "$HOME/.config/fastfetch/config.jsonc" ]; then
            rm -f "$HOME/.config/fastfetch/config.jsonc"
        fi
        ln -sf "$DOTFILES_DIR/config/fastfetch/macos.jsonc" "$HOME/.config/fastfetch/config.jsonc"
        printf "%b\n" "${GREEN}Symlinked fastfetch config from dotfiles${RC}"
    else
        printf "%b\n" "${YELLOW}fastfetch config not found in dotfiles repo, skipping...${RC}"
    fi

    # Symlink mise config
    if [ -f "$DOTFILES_DIR/config/mise/config.toml" ]; then
        if [ -L "$HOME/.config/mise/config.toml" ] || [ -f "$HOME/.config/mise/config.toml" ]; then
            rm -f "$HOME/.config/mise/config.toml"
        fi
        ln -sf "$DOTFILES_DIR/config/mise/config.toml" "$HOME/.config/mise/config.toml"
        printf "%b\n" "${GREEN}Symlinked mise config from dotfiles${RC}"
    else
        printf "%b\n" "${YELLOW}mise config not found in dotfiles repo, skipping...${RC}"
    fi

    printf "%b\n" "${GREEN}All configuration files symlinked successfully! Restart your shell to see changes.${RC}"
}

checkEnv
cloneDotfiles
backupExistingConfigs
installZshDepend
symlinkConfigs
