#!/bin/sh -e
#
# Standalone system update script — safe to run via:
#   curl -fsSL https://raw.githubusercontent.com/.../system-update-standalone.sh | sh
#
# Inlines the minimal common-script.sh bits needed so there are no file dependencies.
# checkCurrentDirectoryWritable is skipped when run via pipe (no script path).
#

# --- Inlined from common-script.sh (minimal set for this script) ---
RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
MAGENTA='\033[35m'

command_exists() {
    for cmd in "$@"; do
        export PATH="$HOME/.local/share/flatpak/exports/bin:/var/lib/flatpak/exports/bin:$PATH"
        command -v "$cmd" >/dev/null 2>&1 || return 1
    done
    return 0
}

checkArch() {
    case "$(uname -m)" in
        x86_64 | amd64) ARCH="x86_64" ;;
        aarch64 | arm64) ARCH="aarch64" ;;
        armv7l) ARCH="armv7l" ;;
        *) printf "%b\n" "${RED}Unsupported architecture: $(uname -m)${RC}" && exit 1 ;;
    esac
    printf "%b\n" "${CYAN}System architecture: ${MAGENTA}${ARCH}${RC}"
}

checkEscalationTool() {
    if [ -z "$ESCALATION_TOOL_CHECKED" ]; then
        if [ "$(id -u)" = "0" ]; then
            ESCALATION_TOOL="eval"
            ESCALATION_TOOL_CHECKED=true
            printf "%b\n" "${CYAN}Running as ${MAGENTA}root${RC}${CYAN}, no escalation needed${RC}"
            return 0
        fi
        ESCALATION_TOOLS='sudo-rs sudo doas'
        for tool in ${ESCALATION_TOOLS}; do
            if command_exists "${tool}"; then
                ESCALATION_TOOL=${tool}
                printf "%b\n" "${CYAN}Using ${MAGENTA}${tool}${RC}${CYAN} for privilege escalation${RC}"
                ESCALATION_TOOL_CHECKED=true
                return 0
            fi
        done
        printf "%b\n" "${RED}Can't find a supported escalation tool${RC}"
        exit 1
    fi
}

checkCommandRequirements() {
    REQUIREMENTS=$1
    MISSING_REQS=""
    for req in ${REQUIREMENTS}; do
        if ! command_exists "${req}"; then
            MISSING_REQS="$MISSING_REQS $req"
        fi
    done
    if [ -n "$MISSING_REQS" ]; then
        printf "%b\n" "${YELLOW}Missing requirements:${MISSING_REQS}${RC}"
        return 1
    fi
    return 0
}

checkPackageManager() {
    if [ -f /run/ostree-booted ] && command_exists "rpm-ostree"; then
        PACKAGER="rpm-ostree"
        printf "%b\n" "${CYAN}Using ${MAGENTA}rpm-ostree${RC}${CYAN} (OSTree/Atomic system)${RC}"
    else
        PACKAGEMANAGER=$1
        for pgm in ${PACKAGEMANAGER}; do
            if command_exists "${pgm}"; then
                PACKAGER=${pgm}
                printf "%b\n" "${CYAN}Using ${MAGENTA}${pgm}${RC}${CYAN} as package manager${RC}"
                break
            fi
        done
        if [ "$PACKAGER" = "apk" ] && grep -qE '^#.*community' /etc/apk/repositories 2>/dev/null; then
            "$ESCALATION_TOOL" sed -i '/community/s/^#//' /etc/apk/repositories
            "$ESCALATION_TOOL" "$PACKAGER" update
        fi
        if [ "$PACKAGER" = "pkg" ]; then
            "$ESCALATION_TOOL" "$PACKAGER" update
        fi
    fi
    if [ -z "$PACKAGER" ]; then
        printf "%b\n" "${RED}Can't find a supported package manager${RC}"
        exit 1
    fi
}

checkSuperUser() {
    SUPERUSERGROUP='wheel sudo root'
    for sug in ${SUPERUSERGROUP}; do
        if id -Gn | grep -q "${sug}"; then
            SUGROUP=${sug}
            printf "%b\n" "${CYAN}Super user group ${MAGENTA}${SUGROUP}${RC}"
            break
        fi
    done
    if ! id -Gn | grep -q "${SUGROUP}"; then
        printf "%b\n" "${RED}You need to be a member of the sudo group to run me!${RC}"
        exit 1
    fi
}

checkCurrentDirectoryWritable() {
    # When run via curl|sh there is no script path; skip this check.
    case "$0" in
        *system-update*) ;;
        *) return 0 ;;
    esac
    GITPATH="$(dirname "$(realpath "$0" 2>/dev/null || echo "$0")")"
    [ -z "$GITPATH" ] || [ "$GITPATH" = "." ] && return 0
    if [ ! -w "$GITPATH" ]; then
        printf "%b\n" "${RED}Can't write to $GITPATH${RC}"
        exit 1
    fi
}

checkDistro() {
    DTYPE="unknown"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DTYPE=$ID
    fi
}

checkAURHelper() {
    if [ "$PACKAGER" = "pacman" ] && [ -z "$SKIP_AUR_CHECK" ]; then
        if [ -z "$AUR_HELPER_CHECKED" ]; then
            AUR_HELPERS="yay paru"
            for helper in ${AUR_HELPERS}; do
                if command_exists "${helper}"; then
                    AUR_HELPER=${helper}
                    printf "%b\n" "${CYAN}Using ${helper} as AUR helper${RC}"
                    AUR_HELPER_CHECKED=true
                    return 0
                fi
            done
            printf "%b\n" "${YELLOW}Installing yay as AUR helper...${RC}"
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm base-devel
            cd /opt && "$ESCALATION_TOOL" git clone https://aur.archlinux.org/yay-bin.git && "$ESCALATION_TOOL" chown -R "$USER":"$USER" ./yay-bin
            cd yay-bin && makepkg --noconfirm -si
            if command_exists yay; then
                AUR_HELPER="yay"
                AUR_HELPER_CHECKED=true
            else
                printf "%b\n" "${RED}Failed to install AUR helper.${RC}"
                exit 1
            fi
        fi
    fi
}

checkEnv() {
    checkArch
    checkEscalationTool
    checkCommandRequirements "curl id $ESCALATION_TOOL"
    checkPackageManager 'moss nala apt-get dnf pacman zypper apk xbps-install eopkg pkg'
    checkCurrentDirectoryWritable
    checkSuperUser
    checkDistro
    checkAURHelper
}
# --- End inlined common-script.sh ---

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
        rpm-ostree)
            "$ESCALATION_TOOL" "$PACKAGER" upgrade
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
    if [ -f /etc/pacman.conf ]; then
        "$ESCALATION_TOOL" sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf || printf "%b\n" "${YELLOW}Failed to enable ParallelDownloads for Pacman. Continuing...${RC}"
    elif [ -f /etc/dnf/dnf.conf ] && ! grep -q '^max_parallel_downloads' /etc/dnf/dnf.conf; then
        echo 'max_parallel_downloads=10' | "$ESCALATION_TOOL" tee -a /etc/dnf/dnf.conf || printf "%b\n" "${YELLOW}Failed to enable max_parallel_downloads for DNF. Continuing...${RC}"
    elif [ -f /etc/zypp/zypp.conf ] && ! grep -q '^multiversion' /etc/zypp/zypp.conf; then
        "$ESCALATION_TOOL" sed -i 's/^# download.use_deltarpm = true/download.use_deltarpm = true/' /etc/zypp/zypp.conf || printf "%b\n" "${YELLOW}Failed to enable parallel downloads for Zypper. Continuing...${RC}"
    fi
}

checkEnv
# Pacman: ensure AUR_HELPER is set even with SKIP_AUR_CHECK (use no-op if no helper)
[ "$PACKAGER" = "pacman" ] && [ -z "$AUR_HELPER" ] && AUR_HELPER="true"
enableParallelDownloads
updateSystem
updateFlatpaks
