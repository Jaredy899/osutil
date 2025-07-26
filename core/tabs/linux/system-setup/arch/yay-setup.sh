#!/bin/sh -e

. ../../common-script.sh

# shellcheck disable=SC2034
AUR_HELPER_CHECKED=true

installDepend() {
    case "$PACKAGER" in
        pacman)
            # Check if any AUR helper is already installed
            if ! command_exists yay paru; then
                printf "%b\n" "${YELLOW}Installing yay as AUR helper...${RC}"
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm base-devel git
                cd /opt && "$ESCALATION_TOOL" git clone https://aur.archlinux.org/yay-bin.git && "$ESCALATION_TOOL" chown -R "$USER": ./yay-bin
                cd yay-bin && makepkg --noconfirm -si
                printf "%b\n" "${GREEN}Yay installed${RC}"
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