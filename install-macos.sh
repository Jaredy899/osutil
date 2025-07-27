#!/bin/bash -e

# Prevent execution if this script was only partially downloaded
{
# Define color codes using echo -e to avoid shell interpretation issues
rc='\033[0m'
red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
    echo -e "${red}ERROR: This installer is designed for macOS only${rc}"
    exit 1
fi

getUrl() {
    echo "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-macos"
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

echo -e "${blue}Installing osutil for macOS...${rc}"

# Create installation directory if it doesn't exist
if [ ! -d "$installDir" ]; then
    echo "Creating directory: $installDir"
    mkdir -p "$installDir"
fi

# Download the binary
temp_file=$(mktemp)
if [ $? -ne 0 ]; then
    echo -e "${red}ERROR: Creating the temporary file${rc}"
    exit 1
fi

echo "Downloading osutil..."
if ! curl -fsL "$(getUrl)" -o "$temp_file"; then
    echo -e "${red}ERROR: Downloading osutil${rc}"
    rm -f "$temp_file"
    exit 1
fi

# Make it executable
if ! chmod +x "$temp_file"; then
    echo -e "${red}ERROR: Making osutil executable${rc}"
    rm -f "$temp_file"
    exit 1
fi

# Remove quarantine attribute to avoid Gatekeeper warning
xattr -d com.apple.quarantine "$temp_file" 2>/dev/null || true

# Move to installation location
if ! mv "$temp_file" "$installPath"; then
    echo -e "${red}ERROR: Installing osutil to $installPath${rc}"
    rm -f "$temp_file"
    exit 1
fi

# Remove quarantine attribute from installed binary
xattr -d com.apple.quarantine "$installPath" 2>/dev/null || true

echo -e "${green}✓ osutil installed successfully to $installPath${rc}"

# Check if the installation directory is in PATH
if echo "$PATH" | grep -q "$installDir"; then
    echo -e "${green}✓ osutil is ready to use!${rc}"
else
    echo -e "${blue}⚠  Please add $installDir to your PATH or restart your terminal${rc}"
    echo "   You can run: export PATH=\"\$PATH:$installDir\""
fi

echo ""
echo "Running osutil..."
exec "$installPath"

} # End of wrapping 