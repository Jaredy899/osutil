#!/bin/sh -e

. ../../common-script.sh

installOnlyOffice() {
    if ! command_exists org.onlyoffice.desktopeditors && ! command_exists onlyoffice-desktopeditors; then
        printf "%b\n" "${YELLOW}Installing Only Office...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -O https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb
                installPkg ./onlyoffice-desktopeditors_amd64.deb
                ;;
            pacman)
                installAurPkg onlyoffice
                ;;
            zypper|dnf|xbps-install|eopkg|apk|moss|rpm-ostree|pkg)
                installFlatpak org.onlyoffice.desktopeditors
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Only Office is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installOnlyOffice
