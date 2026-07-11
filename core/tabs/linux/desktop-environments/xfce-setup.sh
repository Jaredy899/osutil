#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Set desktop environment name and display manager preferences
DE_NAME="XFCE"
export DEFAULT_DM="lightdm"
export DM_OPTIONS="lightdm gdm sddm none"
export DM_LABELS="LightDM|GDM|SDDM|None (Start XFCE manually)"

# Source the common display manager script
. ./common-dm-script.sh

installXFCE() {
    printf "%b\n" "${CYAN}Installing XFCE Desktop Environment...${RC}"
    
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            installPkg xfce4 xfce4-goodies
            installDisplayManager
            ;;
        dnf)
            installGroup xfce-desktop-environment
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            installPkg xfce4 xfce4-goodies
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            installGroup patterns-xfce-xfce
            installDisplayManager
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" update-repo
            installPkg xfce4-session xfce4-panel
            installDisplayManager
            ;;
        apk)
            echo "xfce" | "$ESCALATION_TOOL" setup-desktop
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Su
            installPkg xfce4
            installDisplayManager
            ;;
        *)
            unsupportedPackager
            ;;
    esac
    
    # Print success message if not Alpine Linux
    if [ "$PACKAGER" != "apk" ]; then
        printDMMessage "$DE_NAME" "startxfce4"
    fi
}

# Main execution flow
checkEnv
checkEscalationTool
if [ "$PACKAGER" != "apk" ]; then
    checkDisplayManager
fi
installXFCE
