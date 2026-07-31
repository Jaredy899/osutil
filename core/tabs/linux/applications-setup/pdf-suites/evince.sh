#!/bin/sh -e

. ../../common-script.sh

installEvince() {
    if ! command_exists evince; then
        printf "%b\n" "${YELLOW}Installing Evince...${RC}"
        case "$PACKAGER" in
            pacman|apk|xbps-install|apt-get|nala|dnf|zypper|eopkg|moss|rpm-ostree|pkg)
                installPkg evince
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Evince is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installEvince
