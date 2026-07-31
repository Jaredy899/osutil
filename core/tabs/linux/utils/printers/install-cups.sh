#!/bin/sh -e

. ../../common-script.sh

installCUPS() {
    clear

    printf "%b\n" "${YELLOW}Installing CUPS...${RC}"
    case "$PACKAGER" in
        pacman|apt-get|nala|dnf|eopkg|moss|zypper|apk|xbps-install|rpm-ostree|pkg)
            installPkg cups
            ;;
        *)
            unsupportedPackager
            ;;
    esac
}

# Only auto-run when executed directly (epson/hp scripts source this file)
case "${0##*/}" in
    install-cups.sh)
        checkEnv
        checkEscalationTool
        installCUPS
        ;;
esac
