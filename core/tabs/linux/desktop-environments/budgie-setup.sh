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
            installGroup budgie-desktop-environment
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            installPkg budgie-desktop budgie-control-center budgie-backgrounds budgie-desktop-view budgie-session budgie-extras ghostty
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            installGroup patterns-budgie-budgie
            installDisplayManager
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" update-repo
            installPkg budgie-desktop
            installDisplayManager
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Su
            installPkg budgie-desktop
            installDisplayManager
            ;;
        *)
            unsupportedPackager
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
