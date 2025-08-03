#!/bin/sh -e

# shellcheck disable=SC2034

. ../common-script.sh
. ../common-service-script.sh

# Set desktop environment name and display manager preferences
DE_NAME="Deepin"
DEFAULT_DM="lightdm"
DM_OPTIONS="lightdm gdm sddm none"
DM_LABELS="LightDM|GDM|SDDM|None (Start Deepin manually)"

# Source the common display manager script
. ./common-dm-script.sh

installDeepin() {
    printf "%b\n" "${CYAN}Installing Deepin Desktop Environment...${RC}"
    
    case "$PACKAGER" in
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" group install -y deepin-desktop-environment
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm deepin deepin-kwin deepin-extra
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGER" install -y -t pattern deepin
            installDisplayManager
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Su
            "$ESCALATION_TOOL" "$PACKAGER" -y deepin deepin-desktop
            installDisplayManager
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac
    
    # Print success message
    printDMMessage "$DE_NAME" "startdde"
}

# Main execution flow
checkEnv
checkEscalationTool
checkDisplayManager
installDeepin 