#!/bin/sh -e

. ../../common-script.sh

installJitsi() {
    if ! command_exists org.jitsi.jitsi-meet && ! command_exists jitsi-meet; then
        printf "%b\n" "${YELLOW}Installing Jitsi meet...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                installPkg gnupg2
                curl -fsSL https://download.jitsi.org/jitsi-key.gpg.key | "$ESCALATION_TOOL" apt-key add -
                printf "%b\n" 'deb https://download.jitsi.org stable/' | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null
                "$ESCALATION_TOOL" "$PACKAGER" update
                installPkg jitsi-meet
                ;;
            zypper)
                installPkg jitsi
                ;;
            pacman)
                installAurPkg jitsi-meet-bin
                ;;
            dnf)
                installPkg jitsi-meet
                ;;
            apk|xbps-install|moss|rpm-ostree|eopkg|pkg)
                installFlatpak org.jitsi.jitsi-meet
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Jitsi meet is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installJitsi
