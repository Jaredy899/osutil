#!/bin/sh -e

# Prevent execution if this script was only partially downloaded
{
rc='\033[0m'
red='\033[0;31m'
yellow='\033[1;33m'

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

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
    check 1 "This utility is designed for macOS only"
fi

getUrl() {
    echo "https://github.com/Jaredy899/jaredmacutil/releases/latest/download/macutil"
}

# Check if release exists
checkRelease() {
    printf '%sChecking for latest release...%s\n' "$yellow" "$rc"
    if ! curl -fsL -o /dev/null "$(getUrl)" 2>/dev/null; then
        printf '%sNo release found. Please check: https://github.com/Jaredy899/jaredmacutil/releases%s\n' "$yellow" "$rc"
        printf '%sYou can also build from source: git clone https://github.com/Jaredy899/jaredmacutil && cd jaredmacutil && cargo build --release%s\n' "$yellow" "$rc"
        exit 1
    fi
}

checkRelease
temp_file=$(mktemp)
check $? "Creating the temporary file"

curl -fsL "$(getUrl)" -o "$temp_file"
check $? "Downloading macutil"

chmod +x "$temp_file"
check $? "Making macutil executable"

"$temp_file" "$@"
check $? "Executing macutil"

rm -f "$temp_file"
check $? "Deleting the temporary file"
} # End of wrapping
