#!/bin/sh -e

. ../../common-script.sh

installWarp() {
    if command_exists warp-terminal; then
        printf "%b\n" "${GREEN}Warp is already installed.${RC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing Warp...${RC}"
    
    ARCH=$(uname -m)
    if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ]; then
        printf "%b\n" "${RED}Unsupported architecture: $ARCH${RC}"
        return 1
    fi

    ARCH_SUFFIX=""
    [ "$ARCH" = "aarch64" ] && ARCH_SUFFIX="_arm64"

    case "$PACKAGER" in
        pacman)
            if command -v yay >/dev/null 2>&1; then
                "$AUR_HELPER" -S --needed --noconfirm warp-terminal && return 0
            fi
            
            TEMP_FILE="warp-latest.pkg.tar.zst"
            curl -o "$TEMP_FILE" -JLO "https://app.warp.dev/download?package=pacman${ARCH_SUFFIX}"
            sudo pacman -U "$TEMP_FILE"
            ;;
        apt-get|nala)
            TEMP_FILE="warp-latest.deb"
            curl -o "$TEMP_FILE" -JLO "https://app.warp.dev/download?package=deb${ARCH_SUFFIX}"
            "$ESCALATION_TOOL" dpkg -i "$TEMP_FILE" || "$ESCALATION_TOOL" "$PACKAGER" install -f
            ;;
        dnf|zypper)
            TEMP_FILE="warp-latest.rpm"
            curl -o "$TEMP_FILE" -JLO "https://app.warp.dev/download?package=rpm${ARCH_SUFFIX}"
            
            if [ "$PACKAGER" = "zypper" ]; then
                "$ESCALATION_TOOL" rpm --import https://releases.warp.dev/linux/keys/warp.asc
                "$ESCALATION_TOOL" zypper --no-gpg-checks install -y "$TEMP_FILE"
            else
                "$ESCALATION_TOOL" rpm -i "$TEMP_FILE"
            fi
            ;;
        slapt-get)
            "$ESCALATION_TOOL" slapt-src -y -i warp-terminal
            ;;
        *)
            # AppImage installation
            APPIMAGE_NAME="Warp-$([ "$ARCH" = "x86_64" ] && echo "x64" || echo "ARM64").AppImage"
            appimage_path="$HOME/.local/bin/$APPIMAGE_NAME"
            
            mkdir -p "$HOME/.local/bin"
            curl -L "https://app.warp.dev/download?package=appimage${ARCH_SUFFIX}" -o "$appimage_path"
            chmod +x "$appimage_path"

            # Create desktop entry
            mkdir -p "$HOME/.local/share/applications" "$HOME/.local/share/icons"
            ICON_PATH="$HOME/.local/share/icons/warp.png"
            
            # Extract icon from the AppImage
            "$appimage_path" --appimage-extract dev.warp.Warp.png >/dev/null
            mv squashfs-root/dev.warp.Warp.png "$ICON_PATH"
            rm -rf squashfs-root
            
            cat <<EOF > "$HOME/.local/share/applications/warp.desktop"
[Desktop Entry]
Name=Warp
Exec=$appimage_path
Icon=$ICON_PATH
Type=Application
Categories=Utility;
EOF
            ;;
    esac
}

checkEnv
checkEscalationTool
installWarp