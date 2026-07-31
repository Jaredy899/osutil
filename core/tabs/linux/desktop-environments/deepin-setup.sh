#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Set desktop environment name and display manager preferences
DE_NAME="Deepin"
export DEFAULT_DM="lightdm"
export DM_OPTIONS="lightdm gdm sddm none"
export DM_LABELS="LightDM|GDM|SDDM|None (Start Deepin manually)"

# Source the common display manager script
. ./common-dm-script.sh

installDeepin() {
    printf "%b\n" "${CYAN}Installing Deepin Desktop Environment...${RC}"
    
    case "$PACKAGER" in
        dnf)
            installGroup deepin-desktop-environment
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            installPkg deepin deepin-kwin deepin-extra
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            installGroup deepin
            installDisplayManager
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Su
            installPkg deepin deepin-desktop
            installDisplayManager
            ;;
        *)
            unsupportedPackager
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
