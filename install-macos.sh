#!/bin/bash -e

# Prevent execution if this script was only partially downloaded
{
check() {
    exit_code=$1
    message=$2

    if [ "$exit_code" -ne 0 ]; then
        echo "ERROR: ${message}"
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

echo "Installing osutil for macOS..."

temp_file=$(mktemp)
check $? "Creating the temporary file"

echo "Downloading osutil..."
curl -fsL "$(getUrl)" -o "$temp_file"
check $? "Downloading osutil"

chmod +x "$temp_file"
check $? "Making osutil executable"

# Remove quarantine attribute to avoid Gatekeeper warning
xattr -d com.apple.quarantine "$temp_file" 2>/dev/null || true

echo "✓ osutil downloaded successfully"
echo ""
echo "Running osutil..."

# Run the binary and capture its exit code
"$temp_file" "$@"
exit_code=$?

# Clean up silently
rm -f "$temp_file"

# Exit with the same code as the binary
exit $exit_code
} # End of wrapping 