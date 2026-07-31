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
            installAurPkg $DEPENDENCIES || true
            ;;
        apt-get|nala)
            COMPILEDEPS='build-essential'
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" dpkg --add-architecture i386 || true
            "$ESCALATION_TOOL" "$PACKAGER" update
            installPkg $DEPENDENCIES $COMPILEDEPS || true
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" update -y
            if ! "$ESCALATION_TOOL" "$PACKAGER" config-manager --enable powertools 2>/dev/null; then
                "$ESCALATION_TOOL" "$PACKAGER" config-manager --enable crb 2>/dev/null || true
            fi
            installPkg $DEPENDENCIES || true
            if ! installGroup "Development Tools" 2>/dev/null; then
                installGroup development-tools || true
            fi
            installPkg glibc-devel.i686 libgcc.i686 2>/dev/null || printf "%b\n" "${YELLOW}32-bit packages not available for this architecture, continuing...${RC}"
            ;;
        zypper)
            COMPILEDEPS='patterns-devel-base-devel_basis'
            "$ESCALATION_TOOL" "$PACKAGER" refresh 
            installPkg $COMPILEDEPS || true
            installPkg tar tree multitail unzip cmake make jq libgcc_s1-gcc7-32bit glibc-devel-32bit || true
            ;;
        apk)
            installPkg build-base multitail tar tree trash-cli unzip cmake jq || true
            ;;
        xbps-install)
            COMPILEDEPS='base-devel'
            installPkg $DEPENDENCIES $COMPILEDEPS || true
            installPkg void-repo-multilib || true
            installPkg glibc-32bit gcc-multilib || true
            ;;
        eopkg)
            COMPILEDEPS='-c system.devel'
            "$ESCALATION_TOOL" "$PACKAGER" update-repo
            installPkg tar tree unzip cmake make jq || true
            "$ESCALATION_TOOL" "$PACKAGER" install -y $COMPILEDEPS || true
            ;;
        moss)
            installPkg build-essential tar tree cmake make jq unzip ninja || true
            ;;
        rpm-ostree)
            installPkg $DEPENDENCIES || true
            printf "%b\n" "${YELLOW}Reboot to apply layered packages.${RC}"
            ;;
        *)
            installPkg $DEPENDENCIES || true
            ;;
    esac
}

checkEnv
checkAURHelper
checkEscalationTool
installDepend
