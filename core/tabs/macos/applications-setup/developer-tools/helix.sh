#!/bin/sh -e

. ../../common-script.sh

installHelix() {
    if ! command_exists hx && ! command_exists helix; then
        printf "%b\n" "${YELLOW}Installing Helix editor...${RC}"
        if ! brew install helix; then
            printf "%b\n" "${RED}Failed to install Helix. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Helix installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Helix is already installed.${RC}"
    fi
}

configureHelix() {
    HELIX_CONFIG_DIR="$HOME/.config/helix"
    HELIX_CONFIG_FILE="$HELIX_CONFIG_DIR/config.toml"
    
    # Create config directory if it doesn't exist
    if [ ! -d "$HELIX_CONFIG_DIR" ]; then
        printf "%b\n" "${YELLOW}Creating Helix config directory...${RC}"
        mkdir -p "$HELIX_CONFIG_DIR"
    fi
    
    # Check if config already has the theme setting
    if [ -f "$HELIX_CONFIG_FILE" ] && grep -q 'theme = "catppuccin_mocha"' "$HELIX_CONFIG_FILE"; then
        printf "%b\n" "${GREEN}Helix configuration already exists.${RC}"
        return
    fi
    
    # Append configuration to config.toml
    printf "%b\n" "${YELLOW}Configuring Helix...${RC}"
    cat >> "$HELIX_CONFIG_FILE" << 'EOF'
theme = "catppuccin_mocha"

[keys.normal]
q = { q = ":q!" }
Z = { Z = ":wq" }
EOF
    printf "%b\n" "${GREEN}Helix configuration applied successfully!${RC}"
}

checkEnv
installHelix
configureHelix
