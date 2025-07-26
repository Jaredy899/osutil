#!/bin/sh -e

. ../../common-script.sh

# shellcheck disable=SC2034
AUR_HELPER_CHECKED=true

installDepend() {
    case "$PACKAGER" in
        pacman)
            # Check if any AUR helper is already installed
            if ! command_exists paru yay; then
                printf "%b\n" "${YELLOW}Installing paru as AUR helper...${RC}"
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm base-devel git
                cd /opt && "$ESCALATION_TOOL" git clone https://aur.archlinux.org/paru-bin.git && "$ESCALATION_TOOL" chown -R "$USER": ./paru-bin
                cd paru-bin && makepkg --noconfirm -si
                printf "%b\n" "${GREEN}Paru installed${RC}"
            else
                printf "%b\n" "${GREEN}AUR helper already installed${RC}"
            fi
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
installDepend