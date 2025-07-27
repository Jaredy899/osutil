#!/bin/bash -e

# Prevent execution if this script was only partially downloaded
{
# Define color codes using echo -e to avoid shell interpretation issues
rc='\033[0m'
red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'

check() {
    exit_code=$1
    message=$2

    if [ "$exit_code" -ne 0 ]; then
        echo -e "${red}ERROR: ${message}${rc}"
        exit 1
    fi

    unset exit_code
    unset message
}

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
    check 1 "This installer is designed for macOS only"
fi

getUrl() {
    echo "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-macos"
}

echo -e "${blue}Installing osutil for macOS...${rc}"

temp_file=$(mktemp)
check $? "Creating the temporary file"

echo "Downloading osutil..."
curl -fsL "$(getUrl)" -o "$temp_file"
check $? "Downloading osutil"

chmod +x "$temp_file"
check $? "Making osutil executable"

# Remove quarantine attribute to avoid Gatekeeper warning
xattr -d com.apple.quarantine "$temp_file" 2>/dev/null || true

echo -e "${green}✓ osutil downloaded successfully${rc}"
echo ""
echo "Running osutil..."

"$temp_file" "$@"
check $? "Executing osutil"

rm -f "$temp_file"
check $? "Deleting the temporary file"
} # End of wrapping 