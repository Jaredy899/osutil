#!/bin/sh -e

. ../../common-script.sh

installMeld() {
    if ! command_exists org.gnome.meld && ! command_exists meld; then
        printf "%b\n" "${YELLOW}Installing Meld...${RC}"
        case "$PACKAGER" in
            pacman|apt-get|nala|eopkg|moss|rpm-ostree|apk|xbps-install)
                installPkg meld
                ;;
            *)
                installFlatpak org.gnome.meld
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Meld is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installMeld
