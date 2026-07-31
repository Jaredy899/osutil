#!/bin/sh -e

. ../../common-script.sh

installChromium() {
    if ! command_exists chromium && ! command_exists org.chromium.Chromium; then
        printf "%b\n" "${YELLOW}Installing Chromium...${RC}"
        case "$PACKAGER" in
            pacman|apk|xbps-install|apt-get|nala|dnf|zypper|eopkg)
                installPkg chromium
                ;;
            moss|rpm-ostree|pkg)
                # No native chromium package on these; use Flatpak
                installFlatpak org.chromium.Chromium
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Chromium Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installChromium
