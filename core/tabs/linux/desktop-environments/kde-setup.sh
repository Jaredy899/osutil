#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Set desktop environment name and display manager preferences
DE_NAME="KDE Plasma"
DEFAULT_DM="sddm"
DM_OPTIONS="sddm lightdm gdm none"
DM_LABELS="SDDM|LightDM|GDM|None (Start KDE manually)"

# Source the common display manager script
. ./common-dm-script.sh

installKDE() {
    printf "%b\n" "${CYAN}Installing KDE Plasma Desktop Environment...${RC}"
    
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y task-kde-desktop
            installDisplayManager
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" group install -y kde-desktop-environment
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm plasma-meta
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGER" install -y patterns-kde-kde
            installDisplayManager
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" update-repo
            "$ESCALATION_TOOL" "$PACKAGER" install -y plasma-desktop
            installDisplayManager
            ;;
        apk)
            echo "plasma" | "$ESCALATION_TOOL" setup-desktop
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Su
            "$ESCALATION_TOOL" "$PACKAGER" -y plasma-desktop
            installDisplayManager
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac
    
    # Print success message if not Alpine Linux
    if [ "$PACKAGER" != "apk" ]; then
        printDMMessage "$DE_NAME" "startplasma-x11"
    fi
}

# Main execution flow
checkEnv
checkEscalationTool
if [ "$PACKAGER" != "apk" ]; then
    checkDisplayManager
fi
installKDE 