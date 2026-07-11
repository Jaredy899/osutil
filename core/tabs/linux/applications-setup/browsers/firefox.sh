#!/bin/sh -e

. ../../common-script.sh

installFirefox() {
    if ! command_exists firefox && ! command_exists org.mozilla.firefox; then
        printf "%b\n" "${YELLOW}Installing Mozilla Firefox...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                installPkg firefox-esr
                ;;
            zypper)
                installPkg MozillaFirefox
                ;;
            pacman|dnf|eopkg|moss|xbps-install|apk|pkg)
                installPkg firefox
                ;;
            rpm-ostree)
                installFlatpak org.mozilla.firefox
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Firefox Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installFirefox
