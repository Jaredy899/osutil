#!/bin/sh -e

# Prevent execution if this script was only partially downloaded
{
rc='\033[0m'
red='\033[0;31m'

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
    printf '%sERROR: This utility is designed for macOS only%s\n' "$red" "$rc"
    exit 1
fi

getUrl() {
    echo "https://github.com/Jaredy899/jaredmacutil/releases/latest/download/osutil"
}

temp_file=$(mktemp)
if [ $? -ne 0 ]; then
    printf '%sERROR: Creating the temporary file%s\n' "$red" "$rc"
    exit 1
fi

curl -fsL "$(getUrl)" -o "$temp_file"
if [ $? -ne 0 ]; then
    printf '%sERROR: Downloading osutil%s\n' "$red" "$rc"
    rm -f "$temp_file"
    exit 1
fi

chmod +x "$temp_file"
if [ $? -ne 0 ]; then
    printf '%sERROR: Making osutil executable%s\n' "$red" "$rc"
    rm -f "$temp_file"
    exit 1
fi

# Remove quarantine attribute to avoid Gatekeeper warning
xattr -d com.apple.quarantine "$temp_file" 2>/dev/null || true

"$temp_file" "$@"
exit_code=$?

rm -f "$temp_file"
if [ $? -ne 0 ]; then
    printf '%sERROR: Deleting the temporary file%s\n' "$red" "$rc"
fi

exit $exit_code
} # End of wrapping
