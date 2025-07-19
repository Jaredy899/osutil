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
}

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
    check 1 "This utility is designed for macOS only"
fi

getUrl() {
    echo "https://github.com/Jaredy899/jaredmacutil/releases/latest/download/macutil"
}

# Check if release exists
printf '%sChecking for latest release...%s\n' "$yellow" "$rc"
if ! curl -fsL -o /dev/null "$(getUrl)" 2>/dev/null; then
    printf '%sNo release found. Please check: https://github.com/Jaredy899/jaredmacutil/releases%s\n' "$yellow" "$rc"
    printf '%sYou can also build from source: git clone https://github.com/Jaredy899/jaredmacutil && cd jaredmacutil && cargo build --release%s\n' "$yellow" "$rc"
    exit 1
fi

temp_file=$(mktemp)
check $? "Creating the temporary file"

curl -fsL "$(getUrl)" -o "$temp_file"
check $? "Downloading macutil"

chmod +x "$temp_file"
check $? "Making macutil executable"

# Set basic terminal environment
export TERM="${TERM:-xterm-256color}"

# Check if we have a proper terminal for TUI (only when no args and non-interactive)
if [ $# -eq 0 ] && ([ ! -t 0 ] || [ ! -t 1 ]); then
    printf '%sDownloaded macutil successfully!%s\n' "$yellow" "$rc"
    printf '%sTo run the TUI, please use: sh <(curl -fsSL https://raw.githubusercontent.com/Jaredy899/jaredmacutil/main/start.sh)%s\n' "$yellow" "$rc"
    printf '%sOr run the binary directly: %s%s\n' "$yellow" "$temp_file" "$rc"
    printf '%sOr install it permanently: sudo mv %s /usr/local/bin/macutil%s\n' "$yellow" "$temp_file" "$rc"
    printf '%sNote: The temporary file will remain at %s until you move or delete it%s\n' "$yellow" "$temp_file" "$rc"
    exit 0
fi

"$temp_file" "$@"
exit_code=$?

rm -f "$temp_file"
check $? "Deleting the temporary file"

exit $exit_code
} # End of wrapping
