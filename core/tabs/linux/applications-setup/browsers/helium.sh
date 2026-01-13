#!/bin/sh -e

. ../../common-script.sh

installHelium() {
    if ! command_exists helium; then
        printf "%b\n" "${YELLOW}Installing Helium Browser...${RC}"
        
        # Create local bin directory if it doesn't exist
        mkdir -p "$HOME/.local/bin"
        mkdir -p "$HOME/.local/share/applications"
        mkdir -p "$HOME/.local/share/icons"
        
        # Get latest release from GitHub
        printf "%b\n" "${CYAN}Fetching latest Helium release...${RC}"
        latest_release=$(curl -s https://api.github.com/repos/imputnet/helium-linux/releases/latest)
        
        if [ -z "$latest_release" ] || echo "$latest_release" | grep -q "Not Found"; then
            printf "%b\n" "${RED}Failed to fetch Helium release information${RC}"
            exit 1
        fi
        
        # Determine architecture pattern for AppImage
        case "$ARCH" in
            x86_64|amd64)
                arch_pattern="x86_64\|amd64"
                ;;
            aarch64|arm64)
                arch_pattern="arm64\|aarch64"
                ;;
            *)
                printf "%b\n" "${RED}Unsupported architecture: $ARCH${RC}"
                exit 1
                ;;
        esac
        
        # Find AppImage download URL matching the architecture
        appimage_url=$(echo "$latest_release" | grep -o 'https://[^"]*\.AppImage' | grep -i "$arch_pattern" | head -n1)
        
        # Fallback to any AppImage if architecture-specific one not found
        if [ -z "$appimage_url" ]; then
            printf "%b\n" "${YELLOW}Architecture-specific AppImage not found, trying any available...${RC}"
            appimage_url=$(echo "$latest_release" | grep -o 'https://[^"]*\.AppImage' | head -n1)
        fi
        
        if [ -z "$appimage_url" ]; then
            printf "%b\n" "${RED}Failed to find AppImage download URL${RC}"
            exit 1
        fi
        
        # Download AppImage
        appimage_path="$HOME/.local/bin/helium.AppImage"
        printf "%b\n" "${CYAN}Downloading Helium from: $appimage_url${RC}"
        curl -L "$appimage_url" -o "$appimage_path"
        
        if [ ! -f "$appimage_path" ]; then
            printf "%b\n" "${RED}Failed to download Helium AppImage${RC}"
            exit 1
        fi
        
        # Make executable
        chmod +x "$appimage_path"
        
        # Extract desktop file and icon from AppImage
        printf "%b\n" "${CYAN}Extracting desktop file and icon from AppImage...${RC}"
        extract_dir=$(mktemp -d)
        cd "$extract_dir" || exit 1
        
        # Extract the entire AppImage (this is more reliable than extracting individual files)
        "$appimage_path" --appimage-extract 2>&1 || true
        
        # Check if extraction succeeded by looking for squashfs-root
        if [ ! -d "squashfs-root" ]; then
            printf "%b\n" "${RED}Failed to extract AppImage. Make sure FUSE is installed.${RC}"
            printf "%b\n" "${YELLOW}You may need to install: sudo apt install fuse (or equivalent)${RC}"
            cd - >/dev/null || true
            rm -rf "$extract_dir"
            exit 1
        fi
        
        # Find the desktop file
        desktop_file=$(find squashfs-root -name "helium.desktop" | head -n1)
        if [ -z "$desktop_file" ]; then
            # Try finding any .desktop file
            desktop_file=$(find squashfs-root -name "*.desktop" | head -n1)
        fi
        
        if [ -z "$desktop_file" ] || [ ! -f "$desktop_file" ]; then
            printf "%b\n" "${RED}Desktop file not found in AppImage${RC}"
            printf "%b\n" "${YELLOW}Contents of squashfs-root:${RC}"
            ls -la squashfs-root/ 2>&1 || true
            cd - >/dev/null || true
            rm -rf "$extract_dir"
            exit 1
        fi
        
        # Find and extract icon
        icon_path="$HOME/.local/share/icons/helium.png"
        icon_file=$(find squashfs-root -name "helium.png" | head -n1)
        
        if [ -n "$icon_file" ] && [ -f "$icon_file" ]; then
            mv "$icon_file" "$icon_path"
        else
            printf "%b\n" "${YELLOW}Icon file not found, continuing without icon${RC}"
            icon_path="helium"
        fi
        
        # Extract and modify desktop file
        # Update Exec path to point to our AppImage location
        sed "s|^Exec=.*|Exec=$appimage_path|" "$desktop_file" > "$HOME/.local/share/applications/helium.desktop"
        # Update Icon path
        sed -i "s|^Icon=.*|Icon=$icon_path|" "$HOME/.local/share/applications/helium.desktop"
        
        cd - >/dev/null || true
        rm -rf "$extract_dir"
        
        # Create symlink for command access
        if [ ! -L "$HOME/.local/bin/helium" ]; then
            ln -sf "$appimage_path" "$HOME/.local/bin/helium"
        fi
        
        printf "%b\n" "${GREEN}Helium Browser installed successfully!${RC}"
        printf "%b\n" "${CYAN}Note: You may need to add $HOME/.local/bin to your PATH if it's not already there.${RC}"
    else
        printf "%b\n" "${GREEN}Helium Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installHelium
