#!/bin/sh -e

. ../../common-script.sh

installDiscord() {
    if ! command_exists com.discordapp.Discord && ! command_exists discord; then
        printf "%b\n" "${YELLOW}Installing Discord...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -Lo discord.deb "https://discord.com/api/download?platform=linux&format=deb"
                installPkg ./discord.deb
                ;;
            zypper|eopkg|moss)
                installPkg discord
                ;;
            pacman)
                installPkg discord
                ;;
            dnf)
                installPkg "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
                installPkg discord
                ;;
            apk|xbps-install|rpm-ostree|pkg)
                installFlatpak com.discordapp.Discord
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Discord is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installDiscord
