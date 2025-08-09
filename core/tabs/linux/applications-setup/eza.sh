#!/bin/bash

. ../common-script.sh

installEza() {
    if ! command_exists eza; then
        printf "%b\n" "${YELLOW}Installing eza...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm eza
                ;;
            apt-get|nala)
                if "$ESCALATION_TOOL" "$PACKAGER" install -y eza 2>/dev/null; then
                    return 0
                fi
                # Fallback: Use deb.gierens.de for Debian/Ubuntu
                sudo mkdir -p /etc/apt/keyrings
                wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | \
                    sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
                echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | \
                    sudo tee /etc/apt/sources.list.d/gierens.list
                sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
                sudo apt update
                sudo apt install -y eza
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add eza
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy eza
                ;;
            zypper|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y eza
                ;;
            *)
                # Fallback: Manual install for all other/unsupported packagers
                ARCH=$(uname -m)
                case "$ARCH" in
                    x86_64)
                        EZA_FILE="eza_x86_64-unknown-linux-gnu.tar.gz"
                        ;;
                    aarch64)
                        EZA_FILE="eza_aarch64-unknown-linux-gnu.tar.gz"
                        ;;
                    *)
                        printf "%b\n" "${RED}Unsupported architecture: $ARCH${RC}"
                        return 1
                        ;;
                esac
                curl -sSL "https://github.com/eza-community/eza/releases/latest/download/$EZA_FILE" | tar xz
                sudo chmod +x eza
                sudo mv eza /usr/local/bin/eza
                ;;
        esac
    else
        printf "%b\n" "${GREEN}eza is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installEza
