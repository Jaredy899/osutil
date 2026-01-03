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
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y helix
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y helix
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add helix
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy helix
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y helix
                ;;
            pkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y helix
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
        printf "%b\n" "${CYAN}Note: On Arch Linux, use 'helix' command. On other distros, use 'hx' command.${RC}"
    else
        printf "%b\n" "${GREEN}Helix is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installHelix
