#!/bin/sh -e

. ../common-script.sh

# Centralized base URL for configuration files
CONFIG_BASE_URL="${CONFIG_BASE_URL:-https://raw.githubusercontent.com/Jaredy899/linux/refs/heads/main/config_changes}"

installDepend() {
    printf "%b\n" "${YELLOW}Installing required packages...${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" install -y curl zoxide fastfetch starship bat fzf
}

downloadProfile() {
    printf "%b\n" "${YELLOW}Setting up custom shell profile for FreeBSD...${RC}"

    USER_PROFILE="$HOME/.profile"

    # Download and set up custom profile
    printf "%b\n" "${YELLOW}Downloading custom profile...${RC}"
    TEMP_PROFILE="/tmp/profile.tmp"
    if curl -sSLo "$TEMP_PROFILE" "$CONFIG_BASE_URL/profile"; then
        printf "%b\n" "${GREEN}Successfully downloaded custom profile${RC}"

        # Adapt the profile for FreeBSD compatibility
        printf "%b\n" "${YELLOW}Adapting profile for FreeBSD compatibility...${RC}"

        # Create FreeBSD-compatible version using a basic approach
        cp "$TEMP_PROFILE" "${TEMP_PROFILE}.freebsd"

        # Use simple sed commands that work on all systems
        sed 's/ip route/route -n get default/g' "${TEMP_PROFILE}.freebsd" > "${TEMP_PROFILE}.tmp"
        mv "${TEMP_PROFILE}.tmp" "${TEMP_PROFILE}.freebsd"

        sed 's/ip -4 -o addr show/ifconfig/g' "${TEMP_PROFILE}.freebsd" > "${TEMP_PROFILE}.tmp"
        mv "${TEMP_PROFILE}.tmp" "${TEMP_PROFILE}.freebsd"

        sed 's/netstat -nape --inet/netstat -an -p tcp/g' "${TEMP_PROFILE}.freebsd" > "${TEMP_PROFILE}.tmp"
        mv "${TEMP_PROFILE}.tmp" "${TEMP_PROFILE}.freebsd"

        # Remove Alpine-specific lines
        grep -v '/etc/alpine-release' "${TEMP_PROFILE}.freebsd" > "${TEMP_PROFILE}.tmp"
        mv "${TEMP_PROFILE}.tmp" "${TEMP_PROFILE}.freebsd"

        grep -v '/etc/profile.d' "${TEMP_PROFILE}.freebsd" > "${TEMP_PROFILE}.tmp"
        mv "${TEMP_PROFILE}.tmp" "${TEMP_PROFILE}.freebsd"

        mv "${TEMP_PROFILE}.freebsd" "$TEMP_PROFILE"

        # Validate the profile syntax (try both sh and bash)
        printf "%b\n" "${YELLOW}Validating profile syntax...${RC}"
        if command -v bash >/dev/null 2>&1 && bash -n "$TEMP_PROFILE" 2>/dev/null; then
            printf "%b\n" "${GREEN}Profile syntax is valid (bash)${RC}"
        elif sh -n "$TEMP_PROFILE" 2>/dev/null; then
            printf "%b\n" "${GREEN}Profile syntax is valid (sh)${RC}"
        else
            printf "%b\n" "${RED}Profile has syntax errors, creating minimal FreeBSD profile${RC}"
            cat > "$TEMP_PROFILE" << 'EOF'
# Minimal FreeBSD Profile - sh compatible
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export PAGER=less
umask 022

# FreeBSD specific settings
export CLICOLOR=1
export LSCOLORS="Gxfxcxdxbxegedabagacad"

# Basic aliases that work in sh
alias ls='ls -F --color=auto'
alias ll='ls -la'
alias la='ls -A'

# Initialize tools if available (simple check without eval)
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

# Source additional configs if they exist
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

if [ -f "$HOME/.zshrc" ]; then
    . "$HOME/.zshrc"
fi
EOF
        fi

        # Backup existing profile if it exists
        if [ -f "$USER_PROFILE" ] && [ ! -f "$USER_PROFILE.bak" ]; then
            cp "$USER_PROFILE" "$USER_PROFILE.bak"
            printf "%b\n" "${YELLOW}Backed up existing profile to $USER_PROFILE.bak${RC}"
        fi

        # Install user-specific profile
        mv "$TEMP_PROFILE" "$USER_PROFILE"
        printf "%b\n" "${GREEN}FreeBSD-adapted profile installed to $USER_PROFILE${RC}"
        PROFILE_INSTALLED="$USER_PROFILE"
    else
        printf "%b\n" "${RED}Failed to download profile${RC}"
        exit 1
    fi

    # Download fastfetch config
    printf "%b\n" "${YELLOW}Downloading fastfetch config...${RC}"
    mkdir -p "$HOME/.config/fastfetch"
    if curl -sSLo "$HOME/.config/fastfetch/config.jsonc" "$CONFIG_BASE_URL/config.jsonc"; then
        printf "%b\n" "${GREEN}Fastfetch config downloaded successfully${RC}"
    else
        printf "%b\n" "${YELLOW}Could not download fastfetch config, using default${RC}"
    fi

    # Download starship config
    printf "%b\n" "${YELLOW}Downloading starship config...${RC}"
    mkdir -p "$HOME/.config"
    if curl -sSLo "$HOME/.config/starship.toml" "$CONFIG_BASE_URL/starship.toml"; then
        printf "%b\n" "${GREEN}Starship config downloaded successfully${RC}"
    else
        printf "%b\n" "${YELLOW}Could not download starship config, using default${RC}"
    fi

    printf "%b\n" "${GREEN}Profile setup completed! Restart your shell to see the changes.${RC}"
    printf "%b\n" "${CYAN}Note: Configurations are installed in your home directory ($HOME)${RC}"
}

backupExistingProfile() {
    # Backup existing fastfetch config if it exists
    if [ -e "$HOME/.config/fastfetch/config.jsonc" ] && [ ! -e "$HOME/.config/fastfetch/config.jsonc.bak" ]; then
        printf "%b\n" "${YELLOW}Backing up existing fastfetch config to $HOME/.config/fastfetch/config.jsonc.bak${RC}"
        mv "$HOME/.config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc.bak"
    fi

    # Backup existing starship config if it exists
    if [ -e "$HOME/.config/starship.toml" ] && [ ! -e "$HOME/.config/starship.toml.bak" ]; then
        printf "%b\n" "${YELLOW}Backing up existing starship config to $HOME/.config/starship.toml.bak${RC}"
        mv "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak"
    fi
}

checkEnv
checkEscalationTool
installDepend
backupExistingProfile
downloadProfile
