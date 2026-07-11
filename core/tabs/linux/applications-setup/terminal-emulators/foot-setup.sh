#!/bin/sh -e

. ../../common-script.sh


installFoot() {
    if ! command_exists foot; then
        printf "%b\n" "${YELLOW}Installing foot...${RC}"
        case "$PACKAGER" in
            pacman|apk|xbps-install|apt-get|nala|dnf|zypper|eopkg|moss|rpm-ostree|pkg)
                installPkg foot
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}foot is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installFoot
