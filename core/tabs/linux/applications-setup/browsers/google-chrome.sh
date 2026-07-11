#!/bin/sh -e

. ../../common-script.sh

installChrome() {
    if ! command_exists google-chrome && ! command_exists com.google.Chrome; then
        printf "%b\n" "${YELLOW}Installing Google Chrome...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -O https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
                installPkg ./google-chrome-stable_current_amd64.deb
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" addrepo http://dl.google.com/linux/chrome/rpm/stable/x86_64 Google-Chrome
                "$ESCALATION_TOOL" "$PACKAGER" refresh
                installPkg google-chrome-stable
                ;;
            pacman)
                installAurPkg google-chrome
                ;;
            dnf)
                installPkg fedora-workstation-repositories
                "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled google-chrome
                installPkg google-chrome-stable
                ;;
            moss|rpm-ostree|apk|xbps-install|eopkg|pkg)
                installFlatpak com.google.Chrome
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Google Chrome Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installChrome
