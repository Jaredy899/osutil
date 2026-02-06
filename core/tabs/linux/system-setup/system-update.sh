#!/bin/sh -e

. ../common-script.sh

updateSystem() {
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy --noconfirm --needed archlinux-keyring
            "$AUR_HELPER" -Su --noconfirm
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update && "$ESCALATION_TOOL" "$PACKAGER" upgrade -y
            ;;
        dnf|eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" upgrade -y
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive dup
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" upgrade
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu
            ;;
        moss)
            "$ESCALATION_TOOL" "$PACKAGER" -y repo update
            "$ESCALATION_TOOL" "$PACKAGER" -y sync
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
            exit 1
            ;;
    esac
}

updateFlatpaks() {
    if command_exists flatpak; then
        printf "%b\n" "${YELLOW}Updating flatpak packages.${RC}"
        "$ESCALATION_TOOL" flatpak update -y
    fi
}

enableParallelDownloads() {
    # Enable parallel downloads
    if [ -f /etc/pacman.conf ]; then
        "$ESCALATION_TOOL" sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf || printf "%b\n" "${YELLOW}Failed to enable ParallelDownloads for Pacman. Continuing...${RC}"
    elif [ -f /etc/dnf/dnf.conf ] && ! grep -q '^max_parallel_downloads' /etc/dnf/dnf.conf; then
        echo 'max_parallel_downloads=10' | "$ESCALATION_TOOL" tee -a /etc/dnf/dnf.conf || printf "%b\n" "${YELLOW}Failed to enable max_parallel_downloads for DNF. Continuing...${RC}"
    elif [ -f /etc/zypp/zypp.conf ] && ! grep -q '^multiversion' /etc/zypp/zypp.conf; then
        "$ESCALATION_TOOL" sed -i 's/^# download.use_deltarpm = true/download.use_deltarpm = true/' /etc/zypp/zypp.conf || printf "%b\n" "${YELLOW}Failed to enable parallel downloads for Zypper. Continuing...${RC}"
    fi
}

checkEnv
checkAURHelper
checkEscalationTool
enableParallelDownloads
updateSystem
updateFlatpaks