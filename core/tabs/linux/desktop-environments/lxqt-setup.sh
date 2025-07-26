#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Set desktop environment name and display manager preferences
DE_NAME="LXQt"
DEFAULT_DM="sddm"
DM_OPTIONS="sddm lightdm gdm none"
DM_LABELS="SDDM|LightDM|GDM|None (Start LXQt manually)"

# Source the common display manager script
. ./common-dm-script.sh

installLXQt() {
    printf "%b\n" "${CYAN}Installing LXQt Desktop Environment...${RC}"
    
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y task-lxqt-desktop
            installDisplayManager
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" group install -y lxqt-desktop-environment
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm xorg-server xorg-xinit lxqt breeze-icons
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGER" install -y patterns-lxqt-lxqt
            installDisplayManager
            ;;
        apk)
            echo "lxqt" | "$ESCALATION_TOOL" setup-desktop
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Su
            "$ESCALATION_TOOL" "$PACKAGER" -y lxqt
            installDisplayManager
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
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