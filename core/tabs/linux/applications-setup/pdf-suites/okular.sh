#!/bin/sh -e

. ../../common-script.sh

installOkular() {
    if ! command_exists okular; then
        printf "%b\n" "${YELLOW}Installing Okular...${RC}"
        case "$PACKAGER" in
            pacman|apk|xbps-install|apt-get|nala|dnf|zypper|eopkg|moss|rpm-ostree|pkg)
                installPkg okular
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Okular is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installOkular
