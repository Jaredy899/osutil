#!/bin/sh -e

. ../../common-script.sh
. ./install-cups.sh

installHpPrinterDriver() {
    clear

    printf "%b\n" "${YELLOW}Installing HP printer drivers (HPLIP)...${RC}"
    case "$PACKAGER" in
        apt-get|nala|dnf|zypper|eopkg|pacman|xbps-install)
            installPkg hplip
            ;;
        moss|rpm-ostree|apk|pkg)
            printf "%b\n" "${YELLOW}No native HPLIP package for ${PACKAGER}.${RC}"
            printf "%b\n" "${CYAN}CUPS is installed; use IPP Everywhere or vendor tools for HP printers.${RC}"
            ;;
        *)
            unsupportedPackager
            ;;
    esac
}

checkEnv
checkEscalationTool
installCUPS
installHpPrinterDriver
