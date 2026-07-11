#!/bin/sh -e

. ../../common-script.sh

installLibreWolf() {
    if ! command_exists io.gitlab.librewolf-community && ! command_exists librewolf; then
        printf "%b\n" "${YELLOW}Installing Librewolf...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                installPkg gnupg lsb-release apt-transport-https ca-certificates
                distro=$(if echo " una bookworm vanessa focal jammy bullseye vera uma " | grep -q "$(lsb_release -sc)"; then echo "$(lsb_release -sc)"; else echo 'focal'; fi)
                curl -fsSL https://deb.librewolf.net/keyring.gpg | "$ESCALATION_TOOL" gpg --dearmor -o /usr/share/keyrings/librewolf.gpg
                echo "Types: deb
URIs: https://deb.librewolf.net
Suites: $distro
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/librewolf.gpg" | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/librewolf.sources > /dev/null
                "$ESCALATION_TOOL" "$PACKAGER" update
                installPkg librewolf
                ;;
            dnf)
                curl -fsSL https://rpm.librewolf.net/librewolf-repo.repo | pkexec tee /etc/yum.repos.d/librewolf.repo > /dev/null
                installPkg librewolf
                ;;
            zypper)
                "$ESCALATION_TOOL" rpm --import https://rpm.librewolf.net/pubkey.gpg
                "$ESCALATION_TOOL" zypper ar -ef https://rpm.librewolf.net librewolf
                "$ESCALATION_TOOL" zypper refresh
                installPkg librewolf
                ;;
            pacman)
                installAurPkg librewolf-bin
                ;;
            xbps-install)
                printf '%s\n' 'repository=https://github.com/index-0/librewolf-void/releases/latest/download/' | "$ESCALATION_TOOL" tee /etc/xbps.d/20-librewolf.conf > /dev/null
                installPkg librewolf
                ;;
            apk|eopkg|moss|rpm-ostree|pkg)
                installFlatpak io.gitlab.librewolf-community
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}LibreWolf Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installLibreWolf
