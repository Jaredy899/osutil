#!/bin/sh -e

. ../../common-script.sh

installDepend() {
    if ! command_exists curl; then
        printf "%b\n" "${YELLOW}Installing curl...${RC}"
        "$ESCALATION_TOOL" apk add curl
    fi
    
    if ! command_exists zoxide; then
        printf "%b\n" "${YELLOW}Installing zoxide...${RC}"
        "$ESCALATION_TOOL" apk add zoxide
    fi
    
    if ! command_exists fastfetch; then
        printf "%b\n" "${YELLOW}Installing fastfetch...${RC}"
        "$ESCALATION_TOOL" apk add fastfetch
    fi
}

downloadProfile() {
    printf "%b\n" "${YELLOW}Downloading your custom profile...${RC}"
    
    # Download profile
    printf "%b\n" "${YELLOW}Downloading profile...${RC}"
    if ! curl -sSLo "/etc/profile" "https://raw.githubusercontent.com/Jaredy899/linux/refs/heads/main/config_changes/profile"; then
        printf "%b\n" "${RED}Failed to download profile${RC}"
        exit 1
    fi
    
    # Download fastfetch config
    printf "%b\n" "${YELLOW}Downloading fastfetch config...${RC}"
    mkdir -p "$HOME/.config/fastfetch"
    if ! curl -sSLo "$HOME/.config/fastfetch/config.jsonc" "https://raw.githubusercontent.com/Jaredy899/linux/refs/heads/main/config_changes/config.jsonc"; then
        printf "%b\n" "${RED}Failed to download fastfetch config${RC}"
        exit 1
    fi
    
    printf "%b\n" "${GREEN}Profile and fastfetch config downloaded successfully! Restart your shell to see the changes.${RC}"
}

backupExistingProfile() {
    OLD_PROFILE="/etc/profile"
    if [ -e "$OLD_PROFILE" ] && [ ! -e "/etc/profile.bak" ]; then
        printf "%b\n" "${YELLOW}Moving old profile to /etc/profile.bak${RC}"
        if ! mv "$OLD_PROFILE" "/etc/profile.bak"; then
            printf "%b\n" "${RED}Can't move the old profile file!${RC}"
            exit 1
        fi
    fi
    
    # Backup existing fastfetch config if it exists
    if [ -e "$HOME/.config/fastfetch/config.jsonc" ] && [ ! -e "$HOME/.config/fastfetch/config.jsonc.bak" ]; then
        printf "%b\n" "${YELLOW}Backing up existing fastfetch config to $HOME/.config/fastfetch/config.jsonc.bak${RC}"
        mv "$HOME/.config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc.bak"
    fi
}

checkEnv
checkEscalationTool
installDepend
backupExistingProfile
downloadProfile