#!/bin/sh -e

# shellcheck disable=SC2034

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
GREEN='\033[32m'
MAGENTA='\033[35m'

command_exists() {
for cmd in "$@"; do
    export PATH="$HOME/.local/share/flatpak/exports/bin:/var/lib/flatpak/exports/bin:$PATH"
    command -v "$cmd" >/dev/null 2>&1 || return 1
done
return 0
}

checkFlatpak() {
    if ! command_exists flatpak; then
        printf "%b\n" "${YELLOW}Installing Flatpak...${RC}"
        installPkg flatpak
        printf "%b\n" "${YELLOW}Adding Flathub remote...${RC}"
        "$ESCALATION_TOOL" flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        printf "%b\n" "${YELLOW}Applications installed by Flatpak may not appear on your desktop until the user session is restarted...${RC}"
    else
        if ! flatpak remotes | grep -q "flathub"; then
            printf "%b\n" "${YELLOW}Adding Flathub remote...${RC}"
            "$ESCALATION_TOOL" flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        else
            printf "%b\n" "${CYAN}Flatpak is installed${RC}"
        fi
    fi
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

checkAURHelper() {
    ## Check & Install AUR helper
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

checkEscalationTool() {
    ## Check for escalation tools.
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
    ## Check for requirements.
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
    ## Check Package Manager
    ## Prefer rpm-ostree when booted from OSTree (Bazzite, Fedora Silverblue/Kinoite, etc.)
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

    ## Enable apk community packages
    if [ "$PACKAGER" = "apk" ] && grep -qE '^#.*community' /etc/apk/repositories; then
        "$ESCALATION_TOOL" sed -i '/community/s/^#//' /etc/apk/repositories
        "$ESCALATION_TOOL" "$PACKAGER" update
    fi

    ## Handle pkg (FreeBSD) package manager
    if [ "$PACKAGER" = "pkg" ]; then
        # Update package database
        "$ESCALATION_TOOL" "$PACKAGER" update
    fi

    fi

    if [ -z "$PACKAGER" ]; then
        printf "%b\n" "${RED}Can't find a supported package manager${RC}"
        exit 1
    fi
}

checkSuperUser() {
    ## Check SuperUser Group
    SUPERUSERGROUP='wheel sudo root'
    for sug in ${SUPERUSERGROUP}; do
        if id -Gn | grep -q "${sug}"; then
            SUGROUP=${sug}
            printf "%b\n" "${CYAN}Super user group ${MAGENTA}${SUGROUP}${RC}"
            break
        fi
    done

    ## Check if member of the sudo group.
    if ! id -Gn | grep -q "${SUGROUP}"; then
        printf "%b\n" "${RED}You need to be a member of the sudo group to run me!${RC}"
        exit 1
    fi
}

checkCurrentDirectoryWritable() {
    ## Check if the current directory is writable.
    GITPATH="$(dirname "$(realpath "$0")")"
    if [ ! -w "$GITPATH" ]; then
        printf "%b\n" "${RED}Can't write to $GITPATH${RC}"
        exit 1
    fi
}

checkDistro() {
    DTYPE="unknown"  # Default to unknown
    # Use /etc/os-release for modern distro identification
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DTYPE=$ID
    fi
}

## Install packages with the detected package manager.
## Usage: installPkg pkg1 [pkg2 ...]
## Respects pacman/apk/xbps/zypper/dnf/eopkg/moss/rpm-ostree/apt/nala/pkg flags.
installPkg() {
    if [ -z "$PACKAGER" ]; then
        printf "%b\n" "${RED}PACKAGER is not set. Run checkEnv/checkPackageManager first.${RC}"
        return 1
    fi
    if [ "$#" -eq 0 ]; then
        printf "%b\n" "${RED}installPkg: no packages specified${RC}"
        return 1
    fi

    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm "$@"
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y "$@"
            ;;
        dnf|eopkg|moss)
            "$ESCALATION_TOOL" "$PACKAGER" install -y "$@"
            ;;
        rpm-ostree)
            "$ESCALATION_TOOL" "$PACKAGER" install --allow-inactive "$@"
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install "$@"
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add "$@"
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy "$@"
            ;;
        pkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y "$@"
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
            return 1
            ;;
    esac
}

## Install AUR packages (Arch only). Requires checkAURHelper.
## Usage: installAurPkg pkg1 [pkg2 ...]
installAurPkg() {
    if [ "$PACKAGER" != "pacman" ]; then
        printf "%b\n" "${RED}installAurPkg is only for pacman/AUR systems${RC}"
        return 1
    fi
    if [ -z "$AUR_HELPER" ]; then
        checkAURHelper
    fi
    "$AUR_HELPER" -S --needed --noconfirm "$@"
}

## Ensure Flatpak + Flathub, then install one or more Flatpak app IDs.
## Usage: installFlatpak [flathub.]app.id [...]
installFlatpak() {
    if [ "$#" -eq 0 ]; then
        printf "%b\n" "${RED}installFlatpak: no Flatpak IDs specified${RC}"
        return 1
    fi
    checkFlatpak
    for app in "$@"; do
        case "$app" in
            */*)
                "$ESCALATION_TOOL" flatpak install -y "$app"
                ;;
            *)
                "$ESCALATION_TOOL" flatpak install -y flathub "$app"
                ;;
        esac
    done
}

## Install a dnf package group or zypper pattern.
## Usage: installGroup "Development Tools"
##        installGroup xfce-desktop-environment
##        installGroup patterns-xfce-xfce
installGroup() {
    if [ "$#" -eq 0 ]; then
        printf "%b\n" "${RED}installGroup: no group/pattern specified${RC}"
        return 1
    fi
    case "$PACKAGER" in
        dnf)
            if ! "$ESCALATION_TOOL" "$PACKAGER" group install -y "$@" 2>/dev/null; then
                "$ESCALATION_TOOL" "$PACKAGER" groupinstall -y "$@"
            fi
            ;;
        zypper)
            for g in "$@"; do
                case "$g" in
                    patterns-*)
                        installPkg "$g"
                        ;;
                    *)
                        "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install -t pattern "$g"
                        ;;
                esac
            done
            ;;
        *)
            # Fall back to normal packages / @groups for moss etc.
            installPkg "$@"
            ;;
    esac
}

## Abort with a clear unsupported-packager message.
unsupportedPackager() {
    printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
    exit 1
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
