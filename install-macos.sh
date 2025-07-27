#!/bin/bash -e

# Prevent execution if this script was only partially downloaded
{
rc='\033[0m'
red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
    printf '%sERROR: This installer is designed for macOS only%s\n' "$red" "$rc"
    exit 1
fi

getUrl() {
    echo "https://github.com/Jaredy899/jaredmacutil/releases/latest/download/osutil-macos"
}

getInstallPath() {
    # Try to install to /usr/local/bin first, fallback to ~/.local/bin
    if [ -w /usr/local/bin ]; then
        echo "/usr/local/bin/osutil"
    else
        echo "$HOME/.local/bin/osutil"
    fi
}

installPath=$(getInstallPath)
installDir=$(dirname "$installPath")

printf '%sInstalling osutil for macOS...%s\n' "$blue" "$rc"

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

printf 'Downloading osutil...\n'
curl -fsL "$(getUrl)" -o "$temp_file"
if [ $? -ne 0 ]; then
    printf '%sERROR: Downloading osutil%s\n' "$red" "$rc"
    rm -f "$temp_file"
    exit 1
fi

# Make it executable
chmod +x "$temp_file"
if [ $? -ne 0 ]; then
    printf '%sERROR: Making osutil executable%s\n' "$red" "$rc"
    rm -f "$temp_file"
    exit 1
fi

# Remove quarantine attribute to avoid Gatekeeper warning
xattr -d com.apple.quarantine "$temp_file" 2>/dev/null || true

# Move to installation location
mv "$temp_file" "$installPath"
if [ $? -ne 0 ]; then
    printf '%sERROR: Installing osutil to %s%s\n' "$red" "$installPath" "$rc"
    rm -f "$temp_file"
    exit 1
fi

# Remove quarantine attribute from installed binary
xattr -d com.apple.quarantine "$installPath" 2>/dev/null || true

printf '%s✓ osutil installed successfully to %s%s\n' "$green" "$installPath" "$rc"

# Check if the installation directory is in PATH
if echo "$PATH" | grep -q "$installDir"; then
    printf '%s✓ osutil is ready to use!%s\n' "$green" "$rc"
else
    printf '%s⚠  Please add %s to your PATH or restart your terminal%s\n' "$blue" "$installDir" "$rc"
    printf '   You can run: export PATH="$PATH:%s"%s\n' "$installDir" "$rc"
fi

printf '\nUsage: osutil\n'

} # End of wrapping 