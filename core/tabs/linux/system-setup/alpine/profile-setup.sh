#!/bin/sh -e

. ../../common-script.sh

# Centralized dotfiles repository
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Jaredy899/dotfiles.git}"
DOTFILES_DIR="$HOME/.local/share/dotfiles"

installDepend() {
    printf "%b\n" "${YELLOW}Installing required packages...${RC}"
    "$ESCALATION_TOOL" apk add curl zoxide fastfetch starship bat fzf
}

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

downloadProfile() {
    printf "%b\n" "${YELLOW}Symlinking your custom profile and configs...${RC}"

    # Symlink profile from dotfiles repo to /etc/profile
    if [ -f "$DOTFILES_DIR/sh/profile" ]; then
        if [ -L "/etc/profile" ] || [ -f "/etc/profile" ]; then
            "$ESCALATION_TOOL" rm -f "/etc/profile"
        fi
        "$ESCALATION_TOOL" ln -sf "$DOTFILES_DIR/sh/profile" "/etc/profile"
        printf "%b\n" "${GREEN}Symlinked profile from dotfiles${RC}"
    else
        printf "%b\n" "${YELLOW}Profile not found in dotfiles repo, skipping...${RC}"
    fi

    # Symlink fastfetch config from dotfiles repo
    if [ -f "$DOTFILES_DIR/config/fastfetch/config.jsonc" ]; then
        mkdir -p "$HOME/.config/fastfetch"
        if [ -L "$HOME/.config/fastfetch/config.jsonc" ] || [ -f "$HOME/.config/fastfetch/config.jsonc" ]; then
            rm -f "$HOME/.config/fastfetch/config.jsonc"
        fi
        ln -sf "$DOTFILES_DIR/config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
        printf "%b\n" "${GREEN}Symlinked fastfetch config from dotfiles${RC}"
    else
        printf "%b\n" "${YELLOW}Fastfetch config not found in dotfiles repo, skipping...${RC}"
    fi

    # Symlink starship config from dotfiles repo
    if [ -f "$DOTFILES_DIR/config/starship.toml" ]; then
        mkdir -p "$HOME/.config"
        if [ -L "$HOME/.config/starship.toml" ] || [ -f "$HOME/.config/starship.toml" ]; then
            rm -f "$HOME/.config/starship.toml"
        fi
        ln -sf "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"
        printf "%b\n" "${GREEN}Symlinked starship config from dotfiles${RC}"
    else
        printf "%b\n" "${YELLOW}Starship config not found in dotfiles repo, skipping...${RC}"
    fi

    printf "%b\n" "${GREEN}Profile, fastfetch, and starship configs symlinked successfully! Restart your shell to see the changes.${RC}"
}

backupExistingProfile() {
    OLD_PROFILE="/etc/profile"
    if [ -e "$OLD_PROFILE" ] && [ ! -e "/etc/profile.bak" ] && [ ! -L "$OLD_PROFILE" ]; then
        printf "%b\n" "${YELLOW}Moving old profile to /etc/profile.bak${RC}"
        if ! "$ESCALATION_TOOL" mv "$OLD_PROFILE" "/etc/profile.bak"; then
            printf "%b\n" "${RED}Can't move the old profile file!${RC}"
            exit 1
        fi
    fi

    # Backup existing fastfetch config if it exists (skip if it's already a symlink)
    if [ -e "$HOME/.config/fastfetch/config.jsonc" ] && [ ! -e "$HOME/.config/fastfetch/config.jsonc.bak" ] && [ ! -L "$HOME/.config/fastfetch/config.jsonc" ]; then
        printf "%b\n" "${YELLOW}Backing up existing fastfetch config to $HOME/.config/fastfetch/config.jsonc.bak${RC}"
        mv "$HOME/.config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc.bak"
    fi

    # Backup existing starship config if it exists (skip if it's already a symlink)
    if [ -e "$HOME/.config/starship.toml" ] && [ ! -e "$HOME/.config/starship.toml.bak" ] && [ ! -L "$HOME/.config/starship.toml" ]; then
        printf "%b\n" "${YELLOW}Backing up existing starship config to $HOME/.config/starship.toml.bak${RC}"
        mv "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak"
    fi
}

checkEnv
checkEscalationTool
installDepend
cloneDotfiles
backupExistingProfile
downloadProfile