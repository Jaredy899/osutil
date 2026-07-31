#!/bin/sh -e

. ../../common-script.sh

installGhostty() {
    if ! command_exists ghostty; then
        printf "%b\n" "${YELLOW}Installing Ghostty...${RC}"
        case "$PACKAGER" in
            pacman)
                printf "%b\n" "-----------------------------------------------------"
                printf "%b\n" "Select the package to install:"
                printf "%b\n" "1. ${CYAN}ghostty${RC}      (stable release)"
                printf "%b\n" "2. ${CYAN}ghostty-git${RC}  (compiled from the latest commit)"
                printf "%b\n" "-----------------------------------------------------"
                printf "%b" "Enter your choice: "
                read -r choice
                case $choice in
                    1) installPkg ghostty ;;
                    2) installAurPkg ghostty-git ;;
                    *)
                        printf "%b\n" "${RED}Invalid choice:${RC} $choice"
                        return 1
                        ;;
                esac
                ;;
            xbps-install|zypper|eopkg|moss)
                installPkg ghostty
                ;;
            dnf)
                printf "%b\n" "${YELLOW}Enabling Ghostty COPR repository...${RC}"
                "$ESCALATION_TOOL" "$PACKAGER" copr enable scottames/ghostty -y
                installPkg ghostty
                ;;
            apt-get|nala)
                if [ "$DTYPE" = "ubuntu" ]; then
                    UBUNTU_MAJOR="${VERSION_ID%%.*}"
                    if [ -n "$UBUNTU_MAJOR" ] && [ "$UBUNTU_MAJOR" -ge 26 ]; then
                        "$ESCALATION_TOOL" "$PACKAGER" update
                        installPkg ghostty
                    else
                        printf "%b\n" "${RED}Ghostty is only available in Ubuntu repositories for 26.04 and newer.${RC}"
                        return 1
                    fi
                else
                    printf "%b\n" "${RED}Ghostty apt package support is currently enabled only for Ubuntu 26.04+.${RC}"
                    return 1
                fi
                ;;
            *)
                printf "%b\n" "${RED}Binary installation not available for your distribution.${RC}"
                return 1
                ;;
        esac
        printf "%b\n" "${GREEN}Ghostty successfully installed!${RC}"
    else
        printf "%b\n" "${GREEN}Ghostty is already installed!${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installGhostty
