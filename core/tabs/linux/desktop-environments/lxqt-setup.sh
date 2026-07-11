#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Set desktop environment name and display manager preferences
DE_NAME="LXQt"
export DEFAULT_DM="sddm"
export DM_OPTIONS="sddm lightdm gdm none"
export DM_LABELS="SDDM|LightDM|GDM|None (Start LXQt manually)"

# Source the common display manager script
. ./common-dm-script.sh

installLXQt() {
    printf "%b\n" "${CYAN}Installing LXQt Desktop Environment...${RC}"
    
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            installPkg task-lxqt-desktop
            installDisplayManager
            ;;
        dnf)
            installGroup lxqt-desktop-environment
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            installPkg xorg-server xorg-xinit lxqt breeze-icons
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            installGroup patterns-lxqt-lxqt
            installDisplayManager
            ;;
        apk)
            echo "lxqt" | "$ESCALATION_TOOL" setup-desktop
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Su
            installPkg lxqt
            installDisplayManager
            ;;
        *)
            unsupportedPackager
            ;;
    esac
    
    # Print success message if not Alpine Linux
    if [ "$PACKAGER" != "apk" ]; then
        printDMMessage "$DE_NAME" "startlxqt"
    fi
}

# Main execution flow
checkEnv
checkEscalationTool
if [ "$PACKAGER" != "apk" ]; then
    checkDisplayManager
fi
installLXQt
