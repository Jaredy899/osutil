#!/bin/sh -e

# Prevent execution if this script was only partially downloaded
{
rc='\033[0m'
red='\033[0;31m'

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
