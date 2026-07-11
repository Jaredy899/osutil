#!/bin/sh -e

. ../../common-script.sh

installTorBrowser() {
    if ! command_exists torbrowser-launcher && ! command_exists org.torproject.torbrowser-launcher; then
        printf "%b\n" "${YELLOW}Installing Tor Browser...${RC}"
        case "$PACKAGER" in
            apt-get|nala|dnf|eopkg|pacman|xbps-install|zypper)
                installPkg torbrowser-launcher
                ;;
            moss|rpm-ostree|apk|pkg)
                installFlatpak org.torproject.torbrowser-launcher
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Tor Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installTorBrowser
