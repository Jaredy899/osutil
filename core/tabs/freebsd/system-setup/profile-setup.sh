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

        # Create FreeBSD-compatible version using a simpler approach
        cp "$TEMP_PROFILE" "${TEMP_PROFILE}.freebsd"

        # Use sed for simple replacements that are less likely to break syntax
        sed -i \
            -e 's/ip route/route -n get default/g' \
            -e 's/ip -4 -o addr show/ifconfig/g' \
            -e 's/netstat -nape --inet/netstat -an -p tcp/g' \
            -e '/\/etc\/alpine-release/d' \
            -e '/\/etc\/profile\.d/d' \
            "${TEMP_PROFILE}.freebsd"

        mv "${TEMP_PROFILE}.freebsd" "$TEMP_PROFILE"

        # Validate the profile syntax
        printf "%b\n" "${YELLOW}Validating profile syntax...${RC}"
        if sh -n "$TEMP_PROFILE"; then
            printf "%b\n" "${GREEN}Profile syntax is valid${RC}"
        else
            printf "%b\n" "${RED}Profile has syntax errors, using basic FreeBSD profile${RC}"
            cat > "$TEMP_PROFILE" << 'EOF'
# Basic FreeBSD Profile
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export PAGER=less
umask 022

# FreeBSD specific settings
export CLICOLOR=1
export LSCOLORS="Gxfxcxdxbxegedabagacad"

# Load additional configurations
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

if [ -f "$HOME/.zshrc" ]; then
    . "$HOME/.zshrc"
fi

# Initialize tools if available
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
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
