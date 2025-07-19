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

# Check if we have a proper terminal (but don't fail if not)
is_interactive=false
if [ -t 0 ] && [ -t 1 ]; then
    is_interactive=true
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

# Set up terminal environment
export TERM="${TERM:-xterm-256color}"

# Only set COLUMNS/LINES if we're in an interactive terminal
if [ "$is_interactive" = "true" ]; then
    export COLUMNS="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
    export LINES="${LINES:-$(tput lines 2>/dev/null || echo 24)}"
    
    # Run the binary directly
    "$temp_file" "$@"
    exit_code=$?
    
    # Clean up temp file
    rm -f "$temp_file"
    check $? "Deleting the temporary file"
else
    # For non-interactive environments, just download and install
    printf '%sDownloaded macutil successfully!%s\n' "$yellow" "$rc"
    printf '%sTo run the TUI, please execute: %s%s\n' "$yellow" "$temp_file" "$rc"
    printf '%sOr install it permanently: sudo mv %s /usr/local/bin/macutil%s\n' "$yellow" "$temp_file" "$rc"
    printf '%sNote: The temporary file will remain at %s until you move or delete it%s\n' "$yellow" "$temp_file" "$rc"
    exit_code=0
fi

exit $exit_code
} # End of wrapping
