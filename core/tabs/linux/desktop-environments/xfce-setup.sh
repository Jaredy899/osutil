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
            "$ESCALATION_TOOL" "$PACKAGER" install -y xfce4 xfce4-goodies
            installDisplayManager
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" group install -y xfce-desktop-environment
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm xfce4 xfce4-goodies
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGER" install -y patterns-xfce-xfce
            installDisplayManager
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" update-repo
            "$ESCALATION_TOOL" "$PACKAGER" install -y xfce4-session xfce4-panel
            installDisplayManager
            ;;
        apk)
            echo "xfce" | "$ESCALATION_TOOL" setup-desktop
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Su
            "$ESCALATION_TOOL" "$PACKAGER" -y xfce4
            installDisplayManager
            ;;
        pkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y xfce xfce4-goodies slim dbus polkit xorg
            # Enable services (FreeBSD specific)
            "$ESCALATION_TOOL" sysrc dbus_enable=YES
            "$ESCALATION_TOOL" sysrc slim_enable=YES
            "$ESCALATION_TOOL" sysrc moused_enable=YES
            "$ESCALATION_TOOL" service dbus start
            "$ESCALATION_TOOL" service moused start
            printf "%b\n" "${GREEN}XFCE installed on FreeBSD. Configure SLiM and .xinitrc manually.${RC}"
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
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