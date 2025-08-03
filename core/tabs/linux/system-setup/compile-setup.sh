#!/bin/sh -e
# shellcheck disable=SC2086

. ../common-script.sh

installDepend() {
    ## Check for dependencies.
    DEPENDENCIES='tar tree multitail trash-cli unzip cmake make jq'
    printf "%b\n" "${YELLOW}Installing dependencies...${RC}"
    case "$PACKAGER" in
        pacman)
            if ! grep -q "^\s*\[multilib\]" /etc/pacman.conf; then
                echo "[multilib]" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
                echo "Include = /etc/pacman.d/mirrorlist" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
                "$ESCALATION_TOOL" "$PACKAGER" -Syu
            else
                printf "%b\n" "${GREEN}Multilib is already enabled.${RC}"
            fi
            "$AUR_HELPER" -S --needed --noconfirm $DEPENDENCIES || true
            ;;
        apt-get|nala)
            COMPILEDEPS='build-essential'
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" dpkg --add-architecture i386 || true
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y $DEPENDENCIES $COMPILEDEPS || true
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" update -y
            if ! "$ESCALATION_TOOL" "$PACKAGER" config-manager --enable powertools 2>/dev/null; then
                "$ESCALATION_TOOL" "$PACKAGER" config-manager --enable crb 2>/dev/null || true
            fi
            "$ESCALATION_TOOL" "$PACKAGER" -y install $DEPENDENCIES || true
            if ! "$ESCALATION_TOOL" "$PACKAGER" -y group install "Development Tools" 2>/dev/null; then
                "$ESCALATION_TOOL" "$PACKAGER" -y group install development-tools || true
            fi
            "$ESCALATION_TOOL" "$PACKAGER" -y install glibc-devel.i686 libgcc.i686 2>/dev/null || printf "%b\n" "${YELLOW}32-bit packages not available for this architecture, continuing...${RC}"
            ;;
        zypper)
            COMPILEDEPS='patterns-devel-base-devel_basis'
            "$ESCALATION_TOOL" "$PACKAGER" refresh 
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install $COMPILEDEPS || true
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install tar tree multitail unzip cmake make jq libgcc_s1-gcc7-32bit glibc-devel-32bit || true
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add build-base multitail tar tree trash-cli unzip cmake jq || true
            ;;
        xbps-install)
            COMPILEDEPS='base-devel'
            "$ESCALATION_TOOL" "$PACKAGER" -Sy $DEPENDENCIES $COMPILEDEPS || true
            "$ESCALATION_TOOL" "$PACKAGER" -Sy void-repo-multilib || true
            "$ESCALATION_TOOL" "$PACKAGER" -Sy glibc-32bit gcc-multilib || true
            ;;
        eopkg)
            COMPILEDEPS='-c system.devel'
            "$ESCALATION_TOOL" "$PACKAGER" update-repo
            "$ESCALATION_TOOL" "$PACKAGER" install -y tar tree unzip cmake make jq || true
            "$ESCALATION_TOOL" "$PACKAGER" install -y $COMPILEDEPS || true
            ;;
        *)
            "$ESCALATION_TOOL" "$PACKAGER" install -y $DEPENDENCIES || true
            ;;
    esac
}

checkEnv
checkAURHelper
checkEscalationTool
installDepend