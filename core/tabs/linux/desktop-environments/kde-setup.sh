#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Set desktop environment name and display manager preferences
DE_NAME="KDE Plasma"
export DEFAULT_DM="sddm"
export DM_OPTIONS="sddm lightdm gdm none"
export DM_LABELS="SDDM|LightDM|GDM|None (Start KDE manually)"

# Source the common display manager script
. ./common-dm-script.sh

installKDE() {
    printf "%b\n" "${CYAN}Installing KDE Plasma Desktop Environment...${RC}"
    
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            installPkg task-kde-desktop
            installDisplayManager
            ;;
        dnf)
            installGroup kde-desktop-environment
            installDisplayManager
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            installPkg plasma-meta
            installDisplayManager
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            installGroup patterns-kde-kde
            installDisplayManager
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" update-repo
            installPkg plasma-desktop
            installDisplayManager
            ;;
        apk)
            echo "plasma" | "$ESCALATION_TOOL" setup-desktop
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Su
            installPkg plasma-desktop
            installDisplayManager
            ;;
        moss)
            printf "%b\n" "${YELLOW}Select Plasma package set (see https://aerynos.dev/users/desktops/plasma/):${RC}"
            printf "%b\n" "  1) Minimal   - minimum for a Plasma session"
            printf "%b\n" "  2) Recommended (default) - minimal + recommended apps"
            printf "%b\n" "  3) Full      - recommended + all available KDE apps"
            printf "%b" "${YELLOW}Choice (1-3) [2]: ${RC}"
            read -r choice
            case "$choice" in
                1) PKGSET="pkgset-aeryn-plasma-minimal" ;;
                3) PKGSET="pkgset-aeryn-plasma-full" ;;
                *) PKGSET="pkgset-aeryn-plasma-recommended" ;;
            esac
            installPkg "$PKGSET"
            installDisplayManager
            ;;
        *)
            unsupportedPackager
            ;;
    esac

    # Print success message if not Alpine Linux
    if [ "$PACKAGER" != "apk" ]; then
        printDMMessage "$DE_NAME" "startplasma-x11"
        if [ "$PACKAGER" = "moss" ]; then
            printf "%b\n" "${CYAN}Optional: use SDDM or Plasma login: sudo moss install sddm (or plasma-login-manager) && sudo moss remove gdm${RC}"
        fi
    fi
}

# Main execution flow
checkEnv
checkEscalationTool
if [ "$PACKAGER" != "apk" ]; then
    checkDisplayManager
fi
installKDE
