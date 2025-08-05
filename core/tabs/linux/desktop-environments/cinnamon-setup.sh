#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Set desktop environment name and display manager preferences
DE_NAME="Cinnamon"
export DEFAULT_DM="lightdm"
export DM_OPTIONS="lightdm gdm sddm none"
export DM_LABELS="LightDM|GDM|SDDM|None (Start Cinnamon manually)"

# Source the common display manager script
. ./common-dm-script.sh

installCinnamon() {
    printf "%b\n" "${CYAN}Installing Cinnamon Desktop Environment...${RC}"
    
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y cinnamon-desktop-environment
            installDisplayManager
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" group install -y cinnamon-desktop-environment
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm cinnamon
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGER" install -y -t pattern cinnamon
            installDisplayManager
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Su
            "$ESCALATION_TOOL" "$PACKAGER" -y cinnamon-all
            installDisplayManager
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac
    
    # Print success message
    printDMMessage "$DE_NAME" "cinnamon-session"
}

# Main execution flow
checkEnv
checkEscalationTool
checkDisplayManager
installCinnamon 