#!/bin/sh -e

# Prevent execution if this script was only partially downloaded
{
rc='\033[0m'
red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'

# Check if running on Linux
if [ "$(uname)" != "Linux" ]; then
    printf '%sERROR: This installer is designed for Linux only%s\n' "$red" "$rc"
    exit 1
fi

# Detect architecture
detect_architecture() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        armv7l|armv7)
            echo "armv7l"
            ;;
        *)
            printf '%sERROR: Unsupported architecture: %s%s\n' "$red" "$arch" "$rc"
            printf 'Supported architectures: x86_64, aarch64, armv7l\n'
            exit 1
            ;;
    esac
}

getUrl() {
    local arch=$1
    case "$arch" in
        x86_64)
            echo "https://github.com/Jaredy899/jaredmacutil/releases/latest/download/macutil"
            ;;
        aarch64)
            echo "https://github.com/Jaredy899/jaredmacutil/releases/latest/download/macutil-aarch64"
            ;;
        armv7l)
            echo "https://github.com/Jaredy899/jaredmacutil/releases/latest/download/macutil-armv7l"
            ;;
        *)
            printf '%sERROR: Invalid architecture: %s%s\n' "$red" "$arch" "$rc"
            exit 1
            ;;
    esac
}

getInstallPath() {
    # Try to install to /usr/local/bin first, fallback to ~/.local/bin
    if [ -w /usr/local/bin ]; then
        echo "/usr/local/bin/macutil"
    else
        echo "$HOME/.local/bin/macutil"
    fi
}

ARCH=$(detect_architecture)
installPath=$(getInstallPath)
installDir=$(dirname "$installPath")

printf '%sInstalling macutil for Linux (%s)...%s\n' "$blue" "$ARCH" "$rc"

# Create installation directory if it doesn't exist
if [ ! -d "$installDir" ]; then
    printf 'Creating directory: %s\n' "$installDir"
    mkdir -p "$installDir"
fi

# Download the binary
temp_file=$(mktemp)
if [ $? -ne 0 ]; then
    printf '%sERROR: Creating the temporary file%s\n' "$red" "$rc"
    exit 1
fi

printf 'Downloading macutil for %s...\n' "$ARCH"
curl -fsL "$(getUrl "$ARCH")" -o "$temp_file"
if [ $? -ne 0 ]; then
    printf '%sERROR: Downloading macutil for %s%s\n' "$red" "$ARCH" "$rc"
    rm -f "$temp_file"
    exit 1
fi

# Make it executable
chmod +x "$temp_file"
if [ $? -ne 0 ]; then
    printf '%sERROR: Making macutil executable%s\n' "$red" "$rc"
    rm -f "$temp_file"
    exit 1
fi

# Move to installation location
mv "$temp_file" "$installPath"
if [ $? -ne 0 ]; then
    printf '%sERROR: Installing macutil to %s%s\n' "$red" "$installPath" "$rc"
    rm -f "$temp_file"
    exit 1
fi

printf '%s✓ macutil installed successfully to %s%s\n' "$green" "$installPath" "$rc"

# Check if the installation directory is in PATH
if echo "$PATH" | grep -q "$installDir"; then
    printf '%s✓ macutil is ready to use!%s\n' "$green" "$rc"
else
    printf '%s⚠  Please add %s to your PATH or restart your terminal%s\n' "$blue" "$installDir" "$rc"
    printf '   You can run: export PATH="$PATH:%s"%s\n' "$installDir" "$rc"
fi

printf '\nUsage: macutil\n'

} # End of wrapping 