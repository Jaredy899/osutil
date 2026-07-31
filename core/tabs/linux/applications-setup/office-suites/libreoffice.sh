#!/bin/sh -e

. ../../common-script.sh

installLibreOffice() {
    if ! command_exists org.libreoffice.LibreOffice && ! command_exists libreoffice; then
        printf "%b\n" "${YELLOW}Installing Libre Office...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                installPkg libreoffice-core
                ;;
            pacman)
                installPkg libreoffice-fresh
                ;;
            apk|xbps-install|eopkg)
                installPkg libreoffice
                ;;
            zypper|dnf|moss|rpm-ostree|pkg)
                installFlatpak org.libreoffice.LibreOffice
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Libre Office is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installLibreOffice
