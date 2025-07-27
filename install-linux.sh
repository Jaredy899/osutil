#!/bin/sh -e

# Prevent execution if this script was only partially downloaded
{
check() {
    exit_code=$1
    message=$2

    if [ "$exit_code" -ne 0 ]; then
        printf 'ERROR: %s\n' "$message"
        exit 1
    fi

    unset exit_code
    unset message
}

# Check if running on Linux
if [ "$(uname)" != "Linux" ]; then
    check 1 "This installer is designed for Linux only"
fi

findArch() {
    case "$(uname -m)" in
        x86_64|amd64) arch="x86_64" ;;
        aarch64|arm64) arch="aarch64" ;;
        armv7l) arch="armv7l" ;;
        *) check 1 "Unsupported architecture"
    esac
}

getUrl() {
    case "${arch}" in
        x86_64) echo "https://github.com/Jaredy899/osutil/releases/latest/download/osutil";;
        *) echo "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-${arch}";;
    esac
}

findArch
printf 'Installing osutil for Linux (%s)...\n' "$arch"

temp_file=$(mktemp)
check $? "Creating the temporary file"

printf 'Downloading osutil for %s...\n' "$arch"
curl -fsL "$(getUrl)" -o "$temp_file"
check $? "Downloading osutil"

chmod +x "$temp_file"
check $? "Making osutil executable"

printf '✓ osutil downloaded successfully\n'
printf '\nRunning osutil...\n'

# Run the binary and capture its exit code
"$temp_file" "$@"
exit_code=$?

# Clean up silently
rm -f "$temp_file"

# Exit with the same code as the binary
exit $exit_code
} # End of wrapping 