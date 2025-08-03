#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Set desktop environment name and display manager preferences
DE_NAME="Budgie"
export DEFAULT_DM="lightdm"
export DM_OPTIONS="lightdm gdm sddm none"
export DM_LABELS="LightDM|GDM|SDDM|None (Start Budgie manually)"

# Source the common display manager script
. ./common-dm-script.sh

installBudgie() {
    printf "%b\n" "${CYAN}Installing Budgie Desktop Environment...${RC}"
    
    case "$PACKAGER" in
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" group install -y budgie-desktop-environment
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm budgie-desktop budgie-control-center budgie-backgrounds budgie-desktop-view budgie-session budgie-extras ghostty
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGER" install -y patterns-budgie-budgie
            installDisplayManager
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" update-repo
            "$ESCALATION_TOOL" "$PACKAGER" install -y budgie-desktop
            installDisplayManager
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Su
            "$ESCALATION_TOOL" "$PACKAGER" -y budgie-desktop
            installDisplayManager
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac
    
    # Print success message
    printDMMessage "$DE_NAME" "budgie-desktop"
}

# Main execution flow
checkEnv
checkEscalationTool
checkDisplayManager
installBudgie 