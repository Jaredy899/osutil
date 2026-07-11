#!/bin/sh -e

. ../../common-script.sh

installThunderBird() {
    if ! command_exists thunderbird && ! command_exists org.mozilla.Thunderbird; then
        printf "%b\n" "${YELLOW}Installing Thunderbird...${RC}"
        case "$PACKAGER" in
            pacman|apk|xbps-install|apt-get|nala|dnf|zypper|eopkg|moss|pkg)
                installPkg thunderbird
                ;;
            rpm-ostree)
                installFlatpak org.mozilla.Thunderbird
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Thunderbird is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installThunderBird
