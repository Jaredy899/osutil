#!/bin/sh -e

# Prevent execution if this script was only partially downloaded
{
rc='\033[0m'
red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'

check() {
    exit_code=$1
    message=$2

    if [ "$exit_code" -ne 0 ]; then
        printf '%sERROR: %s%s\n' "$red" "$message" "$rc"
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
printf '%sInstalling osutil for Linux (%s)...%s\n' "$blue" "$arch" "$rc"

temp_file=$(mktemp)
check $? "Creating the temporary file"

printf 'Downloading osutil for %s...\n' "$arch"
curl -fsL "$(getUrl)" -o "$temp_file"
check $? "Downloading osutil"

chmod +x "$temp_file"
check $? "Making osutil executable"

printf '%s✓ osutil downloaded successfully%s\n' "$green" "$rc"
printf '\nRunning osutil...\n'

"$temp_file" "$@"
check $? "Executing osutil"

rm -f "$temp_file"
check $? "Deleting the temporary file"
} # End of wrapping 