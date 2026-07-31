#!/bin/sh -e

# shellcheck disable=SC2086

. ../common-script.sh

installDepend() {
    DEPENDENCIES='wine dbus git'
    printf "%b\n" "${YELLOW}Installing dependencies...${RC}"
    case "$PACKAGER" in
        pacman)
            if grep -qi "Artix" /etc/os-release; then # Detect Artix Linux
                # Check for lib32
                if ! grep -q "^\s*\[lib32\]" /etc/pacman.conf; then
                    echo "[lib32]" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
                    echo "Include = /etc/pacman.d/mirrorlist" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
                    "$ESCALATION_TOOL" "$PACKAGER" -Syu
                else
                    printf "%b\n" "${GREEN}lib32 is already enabled.${RC}"
                fi
            else
                # Check for multilib
                if ! grep -q "^\s*\[multilib\]" /etc/pacman.conf; then
                    echo "[multilib]" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
                    echo "Include = /etc/pacman.d/mirrorlist" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
                    "$ESCALATION_TOOL" "$PACKAGER" -Syu
                else
                    printf "%b\n" "${GREEN}Multilib is already enabled.${RC}"
                fi
            fi
            DISTRO_DEPS="gnutls lib32-gnutls base-devel gtk2 gtk3 lib32-gtk2 lib32-gtk3 libpulse lib32-libpulse alsa-lib lib32-alsa-lib \
                alsa-utils alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib giflib lib32-giflib libpng lib32-libpng \
                libldap lib32-libldap openal lib32-openal libxcomposite lib32-libxcomposite libxinerama lib32-libxinerama \
                ncurses lib32-ncurses vulkan-icd-loader lib32-vulkan-icd-loader ocl-icd lib32-ocl-icd libva lib32-libva \
                gst-plugins-base-libs lib32-gst-plugins-base-libs sdl2 lib32-sdl2 v4l-utils lib32-v4l-utils sqlite lib32-sqlite"

            installAurPkg $DEPENDENCIES $DISTRO_DEPS
            ;;
        apt-get | nala)
            "$ESCALATION_TOOL" dpkg --add-architecture i386
            "$ESCALATION_TOOL" "$PACKAGER" update
            
            installPkg $DEPENDENCIES
            
            DISTRO_DEPS="libasound2-plugins:i386 libsdl2-2.0-0:i386 libdbus-1-3:i386 libsqlite3-0:i386 wine32:i386"
            apt-cache show software-properties-common >/dev/null 2>&1 && DISTRO_DEPS="$DISTRO_DEPS software-properties-common"
            
            installPkg $DISTRO_DEPS
            ;;
        dnf)
            printf "%b\n" "${CYAN}Installing rpmfusion repos.${RC}"
            installPkg https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
            "$ESCALATION_TOOL" "$PACKAGER" config-manager setopt --repo fedora-cisco-openh264 enabled=1
    
            installPkg $DEPENDENCIES
            ;;
        rpm-ostree)
            printf "%b\n" "${CYAN}Layering RPM Fusion and gaming deps (reboot to apply).${RC}"
            installPkg https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
            installPkg $DEPENDENCIES
            ;;
        zypper)
            installPkg $DEPENDENCIES
            ;;
        eopkg)
            DISTRO_DEPS="libgnutls libgtk-2 libgtk-3 pulseaudio alsa-lib alsa-plugins giflib libpng openal-soft libxcomposite libxinerama ncurses vulkan ocl-icd libva sdl2 v4l-utils sqlite3"

            installPkg $DEPENDENCIES $DISTRO_DEPS
            ;;
        *)
            unsupportedPackager
            ;;
    esac
}

installAdditionalDepend() {
    case "$PACKAGER" in
        pacman)
            DISTRO_DEPS='steam lutris goverlay'
            installPkg $DISTRO_DEPS
            ;;
        apt-get | nala)
            printf "%b\n" "${YELLOW}Installing Lutris...${RC}"
            lutris_url=$(curl -s https://api.github.com/repos/lutris/lutris/releases/latest | grep "browser_download_url.*\.deb" | cut -d '"' -f 4)
            
            if [ -n "$lutris_url" ]; then
                printf "%b\n" "${YELLOW}Downloading latest Lutris from GitHub...${RC}"
                curl -sSLo lutris.deb "$lutris_url"
                installPkg ./lutris.deb
                rm lutris.deb
                "$ESCALATION_TOOL" "$PACKAGER" update
                installPkg lutris
            fi

            printf "%b\n" "${GREEN}Lutris Installation complete.${RC}"
            printf "%b\n" "${YELLOW}Installing steam...${RC}"
            installPkg steam
            ;;
        dnf)
            DISTRO_DEPS='steam lutris'
            installPkg $DISTRO_DEPS
            ;;
        rpm-ostree)
            DISTRO_DEPS='steam lutris'
            installPkg $DISTRO_DEPS
            ;;
        zypper)
            DISTRO_DEPS='lutris'
            installPkg $DISTRO_DEPS
            ;;
        eopkg)
            DISTRO_DEPS='steam lutris'
            installPkg $DISTRO_DEPS
            ;;
        *)
            unsupportedPackager
            ;;
    esac
}

checkEnv
checkAURHelper
checkEscalationTool
installDepend
installAdditionalDepend
