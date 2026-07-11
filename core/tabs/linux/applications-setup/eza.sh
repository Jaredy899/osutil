#!/bin/sh -e

. ../common-script.sh

installEza() {
    if ! command_exists eza; then
        printf "%b\n" "${YELLOW}Installing eza...${RC}"
        case "$PACKAGER" in
            pacman|apk|xbps-install|zypper|eopkg|moss|dnf|rpm-ostree|pkg)
                installPkg eza
                ;;
            apt-get|nala)
                if installPkg eza 2>/dev/null; then
                    return 0
                fi
                # Fallback: Use deb.gierens.de for Debian/Ubuntu
                "$ESCALATION_TOOL" mkdir -p /etc/apt/keyrings
                wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | \
                    "$ESCALATION_TOOL" gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
                echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | \
                    "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/gierens.list
                "$ESCALATION_TOOL" chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
                "$ESCALATION_TOOL" "$PACKAGER" update
                installPkg eza
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
                "$ESCALATION_TOOL" chmod +x eza
                "$ESCALATION_TOOL" mv eza /usr/local/bin/eza
                ;;
        esac
    else
        printf "%b\n" "${GREEN}eza is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installEza
