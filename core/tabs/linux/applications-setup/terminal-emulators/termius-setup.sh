#!/bin/sh -e

. ../../common-script.sh

installTermius() {
    if ! command_exists termius || ! command_exists termius-app; then
        printf "%b\n" "${YELLOW}Installing Termius...${RC}"
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm termius
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" wget -O termius.deb https://www.termius.com/download/linux/Termius.deb
                "$ESCALATION_TOOL" "$PACKAGER" install -y ./termius.deb
                "$ESCALATION_TOOL" rm termius.deb
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install flathub com.termius.Termius
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Termius is already installed.${RC}"
    fi
}


checkEnv
checkEscalationTool
installTermius
