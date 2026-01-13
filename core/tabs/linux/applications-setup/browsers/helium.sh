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
        
        # Find AppImage download URL
        appimage_url=$(echo "$latest_release" | grep -o 'https://[^"]*\.AppImage' | head -n1)
        
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
        
        # Extract desktop file and icon from AppImage to a temporary directory
        printf "%b\n" "${CYAN}Extracting desktop file and icon from AppImage...${RC}"
        extract_dir=$(mktemp -d)
        cd "$extract_dir" || exit 1
        
        if ! "$appimage_path" --appimage-extract helium.desktop >/dev/null 2>&1; then
            printf "%b\n" "${RED}Failed to extract desktop file from AppImage${RC}"
            rm -rf "$extract_dir"
            exit 1
        fi
        
        if ! "$appimage_path" --appimage-extract helium.png >/dev/null 2>&1; then
            printf "%b\n" "${RED}Failed to extract icon from AppImage${RC}"
            rm -rf "$extract_dir"
            exit 1
        fi
        
        # Move icon to proper location
        icon_path="$HOME/.local/share/icons/helium.png"
        if [ -f "squashfs-root/helium.png" ]; then
            mv "squashfs-root/helium.png" "$icon_path"
        else
            printf "%b\n" "${RED}Icon file not found after extraction${RC}"
            rm -rf "$extract_dir"
            exit 1
        fi
        
        # Extract and modify desktop file
        if [ -f "squashfs-root/helium.desktop" ]; then
            # Update Exec path to point to our AppImage location
            sed "s|^Exec=.*|Exec=$appimage_path|" "squashfs-root/helium.desktop" > "$HOME/.local/share/applications/helium.desktop"
            # Update Icon path
            sed -i "s|^Icon=.*|Icon=$icon_path|" "$HOME/.local/share/applications/helium.desktop"
            cd - >/dev/null || true
            rm -rf "$extract_dir"
        else
            printf "%b\n" "${RED}Desktop file not found after extraction${RC}"
            cd - >/dev/null || true
            rm -rf "$extract_dir"
            exit 1
        fi
        
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
