#!/bin/sh -e

. ../../common-script.sh

installHelix() {
    if ! command_exists hx && ! command_exists helix; then
        printf "%b\n" "${YELLOW}Installing Helix editor...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm helix
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y hx
                ;;
            dnf|zypper|eopkg|moss|rpm-ostree)
                "$ESCALATION_TOOL" "$PACKAGER" install -y helix
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add helix
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy helix
                ;;
            *)
                # Fallback: try installing via cargo if available
                if command_exists cargo; then
                    printf "%b\n" "${YELLOW}Package manager not supported. Installing via Cargo...${RC}"
                    cargo install --git https://github.com/helix-editor/helix --locked hx
                else
                    printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
                    printf "%b\n" "${YELLOW}Please install Helix manually or install Rust/Cargo first.${RC}"
                    exit 1
                fi
                ;;
        esac
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
checkEscalationTool
installHelix
configureHelix