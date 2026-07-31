#!/bin/sh -e

. ../../common-script.sh
. ./install-cups.sh

installEpsonPrinterDriver() {
    clear

    printf "%b\n" "${YELLOW}Installing Epson printer drivers...${RC}"
    case "$PACKAGER" in
        pacman)
            installAurPkg epson-inkjet-printer-escpr
            ;;
        apt-get|nala)
            installPkg printer-driver-escpr
            ;;
        dnf|eopkg|xbps-install)
            installPkg epson-inkjet-printer-escpr
            ;;
        moss|rpm-ostree|apk|zypper|pkg)
            printf "%b\n" "${YELLOW}No native Epson ESC/P-R package for ${PACKAGER}.${RC}"
            printf "%b\n" "${CYAN}CUPS is installed; add the printer via CUPS/system settings or vendor drivers.${RC}"
            ;;
        *)
            unsupportedPackager
            ;;
    esac
}

checkEnv
checkEscalationTool
checkAURHelper
installCUPS
installEpsonPrinterDriver
