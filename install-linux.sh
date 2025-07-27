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
    arch=$(uname -m)
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
    arch=$1
    case "$arch" in
        x86_64)
            echo "https://github.com/Jaredy899/osutil/releases/latest/download/osutil"
            ;;
        aarch64)
            echo "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-aarch64"
            ;;
        armv7l)
            echo "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-armv7l"
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
        echo "/usr/local/bin/osutil"
    else
        echo "$HOME/.local/bin/osutil"
    fi
}

ARCH=$(detect_architecture)
installPath=$(getInstallPath)
installDir=$(dirname "$installPath")

printf '%sInstalling osutil for Linux (%s)...%s\n' "$blue" "$ARCH" "$rc"

# Create installation directory if it doesn't exist
if [ ! -d "$installDir" ]; then
    printf 'Creating directory: %s\n' "$installDir"
    mkdir -p "$installDir"
fi

# Download the binary
temp_file=$(mktemp)
if [ -z "$temp_file" ]; then
    printf '%sERROR: Creating the temporary file%s\n' "$red" "$rc"
    exit 1
fi

printf 'Downloading osutil for %s...\n' "$ARCH"
if ! curl -fsL "$(getUrl "$ARCH")" -o "$temp_file"; then
    printf '%sERROR: Downloading osutil for %s%s\n' "$red" "$ARCH" "$rc"
    rm -f "$temp_file"
    exit 1
fi

# Make it executable
if ! chmod +x "$temp_file"; then
    printf '%sERROR: Making osutil executable%s\n' "$red" "$rc"
    rm -f "$temp_file"
    exit 1
fi

# Move to installation location
if ! mv "$temp_file" "$installPath"; then
    printf '%sERROR: Installing osutil to %s%s\n' "$red" "$installPath" "$rc"
    rm -f "$temp_file"
    exit 1
fi

printf '%s✓ osutil installed successfully to %s%s\n' "$green" "$installPath" "$rc"

# Check if the installation directory is in PATH
if echo "$PATH" | grep -q "$installDir"; then
    printf '%s✓ osutil is ready to use!%s\n' "$green" "$rc"
else
    printf '%s⚠  Please add %s to your PATH or restart your terminal%s\n' "$blue" "$installDir" "$rc"
    printf "   You can run: export PATH=\"\$PATH:%s\"%s\n" "$installDir" "$rc"
fi

printf '\nRunning osutil...\n'
exec "$installPath"

} # End of wrapping 