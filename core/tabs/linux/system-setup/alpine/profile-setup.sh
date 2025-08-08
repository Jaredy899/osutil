#!/bin/sh -e

. ../../common-script.sh

installDepend() {
    printf "%b\n" "${YELLOW}Installing required packages...${RC}"
    "$ESCALATION_TOOL" apk add curl zoxide fastfetch bat fzf
}

downloadProfile() {
    printf "%b\n" "${YELLOW}Downloading your custom profile...${RC}"
    
    # Download profile to a temporary location first
    printf "%b\n" "${YELLOW}Downloading profile...${RC}"
    TEMP_PROFILE="/tmp/profile.tmp"
    if ! curl -sSLo "$TEMP_PROFILE" "https://raw.githubusercontent.com/Jaredy899/linux/refs/heads/main/config_changes/profile"; then
        printf "%b\n" "${RED}Failed to download profile${RC}"
        exit 1
    fi
    
    # Move the downloaded profile to /etc/profile with proper permissions
    if ! "$ESCALATION_TOOL" mv "$TEMP_PROFILE" "/etc/profile"; then
        printf "%b\n" "${RED}Failed to install profile to /etc/profile${RC}"
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
        if ! "$ESCALATION_TOOL" mv "$OLD_PROFILE" "/etc/profile.bak"; then
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