#!/bin/sh -e

# shellcheck source=/dev/null
. ../common-script.sh
. ../common-service-script.sh

# Set desktop environment name and display manager preferences
DE_NAME="MATE"
DEFAULT_DM="lightdm"
DM_OPTIONS="lightdm gdm sddm none"
DM_LABELS="LightDM|GDM|SDDM|None (Start MATE manually)"

# Source the common display manager script
. ./common-dm-script.sh

installMATE() {
    printf "%b\n" "${CYAN}Installing MATE Desktop Environment...${RC}"
    
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y task-mate-desktop
            installDisplayManager
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" group install -y mate-desktop-environment
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm mate mate-extra
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGER" install -y patterns-mate-mate
            installDisplayManager
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" update-repo
            "$ESCALATION_TOOL" "$PACKAGER" install -y mate-desktop
            installDisplayManager
            ;;
        apk)
            echo "mate" | "$ESCALATION_TOOL" setup-desktop
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Su
            "$ESCALATION_TOOL" "$PACKAGER" -y mate
            installDisplayManager
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac
    
    # Print success message if not Alpine Linux
    if [ "$PACKAGER" != "apk" ]; then
        printDMMessage "$DE_NAME" "mate-session"
    fi
}

# Main execution flow
checkEnv
checkEscalationTool
if [ "$PACKAGER" != "apk" ]; then
    checkDisplayManager
fi
installMATE 