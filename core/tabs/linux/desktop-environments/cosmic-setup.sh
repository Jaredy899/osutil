#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Set desktop environment name and display manager preferences
DE_NAME="COSMIC"
export DEFAULT_DM="gdm"
export DM_OPTIONS="gdm lightdm sddm none"
export DM_LABELS="GDM|LightDM|SDDM|None (Start COSMIC manually)"

# Source the common display manager script
. ./common-dm-script.sh

installCOSMIC() {
    printf "%b\n" "${CYAN}Installing COSMIC Desktop Environment...${RC}"

    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
            printf "%b\n" "${YELLOW}Select COSMIC install:${RC}"
            printf "%b\n" "  1) Minimal (default) - cosmic-session only"
            printf "%b\n" "  2) Full            - cosmic meta-package (session + apps)"
            printf "%b" "${YELLOW}Choice (1-2) [1]: ${RC}"
            read -r choice
            case "$choice" in
                2) "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm cosmic ;;
                *) "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm cosmic-session ;;
            esac
            installDisplayManager
            ;;
        moss)
            printf "%b\n" "${YELLOW}Select COSMIC package set (see https://aerynos.dev/users/desktops/cosmic/):${RC}"
            printf "%b\n" "  1) Minimal   - minimum for a COSMIC session"
            printf "%b\n" "  2) Recommended (default) - minimal + recommended apps"
            printf "%b\n" "  3) Full      - recommended + optional apps"
            printf "%b" "${YELLOW}Choice (1-3) [2]: ${RC}"
            read -r choice
            case "$choice" in
                1) PKGSET="pkgset-aeryn-cosmic-minimal" ;;
                3) PKGSET="pkgset-aeryn-cosmic-full" ;;
                *) PKGSET="pkgset-aeryn-cosmic-recommended" ;;
            esac
            "$ESCALATION_TOOL" moss install -y "$PKGSET"
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager for COSMIC: $PACKAGER${RC}"
            exit 1
            ;;
    esac

    if [ "$PACKAGER" = "moss" ]; then
        printDMMessage "$DE_NAME" "cosmic-session"
        printf "%b\n" "${CYAN}Optional: use COSMIC greeter instead of GDM: sudo moss install cosmic-greeter && sudo moss remove gdm${RC}"
    elif [ "$PACKAGER" = "pacman" ]; then
        printDMMessage "$DE_NAME" "cosmic-session"
    fi
}

# Main execution flow
checkEnv
checkEscalationTool
if [ "$PACKAGER" = "moss" ] || [ "$PACKAGER" = "pacman" ]; then
    checkDisplayManager
fi
installCOSMIC
