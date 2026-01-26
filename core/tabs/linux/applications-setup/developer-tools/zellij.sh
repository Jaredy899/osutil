#!/bin/sh -e

. ../../common-script.sh

installZellij() {
    if ! command_exists zellij; then
        printf "%b\n" "${YELLOW}Installing Zellij...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm zellij
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy zellij
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add zellij
                ;;
            zypper)
                if [ "$DTYPE" = "opensuse-tumbleweed" ]; then
                    "$ESCALATION_TOOL" "$PACKAGER" install -y zellij
                else
                    printf "%b\n" "${YELLOW}Non-Tumbleweed openSUSE detected, installing from GitHub...${RC}"
                    installZellijFromGitHub
                fi
                ;;
            dnf)
                printf "%b\n" "${YELLOW}Enabling Zellij COPR repository...${RC}"
                "$ESCALATION_TOOL" "$PACKAGER" copr enable verlad/zellij -y
                "$ESCALATION_TOOL" "$PACKAGER" install -y zellij
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y zellij
                ;;
            *)
                installZellijFromGitHub
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Zellij is already installed.${RC}"
    fi
}

installZellijFromGitHub() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            ZELLIJ_FILE="zellij-x86_64-unknown-linux-musl.tar.gz"
            ;;
        aarch64)
            ZELLIJ_FILE="zellij-aarch64-unknown-linux-musl.tar.gz"
            ;;
        armv7l)
            ZELLIJ_FILE="zellij-armv7-unknown-linux-musl.tar.gz"
            ;;
        *)
            printf "%b\n" "${RED}Unsupported architecture: $ARCH${RC}"
            return 1
            ;;
    esac
    curl -sSL "https://github.com/zellij-org/zellij/releases/latest/download/$ZELLIJ_FILE" | tar xz
    "$ESCALATION_TOOL" chmod +x zellij
    "$ESCALATION_TOOL" mv zellij /usr/local/bin/zellij
}

checkEnv
checkEscalationTool
installZellij
