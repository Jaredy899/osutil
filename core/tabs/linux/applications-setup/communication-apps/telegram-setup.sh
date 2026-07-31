#!/bin/sh -e

. ../../common-script.sh

installTelegram() {
    if ! command_exists telegram-desktop && ! command_exists org.telegram.desktop && ! command_exists telegram; then
        printf "%b\n" "${YELLOW}Installing Telegram...${RC}"
        case "$PACKAGER" in
            pacman|apk|xbps-install|apt-get|nala|dnf|zypper)
                installPkg telegram-desktop
                ;;
            eopkg)
                installPkg telegram
                ;;
            moss|rpm-ostree|pkg)
                installFlatpak org.telegram.desktop
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Telegram is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installTelegram
