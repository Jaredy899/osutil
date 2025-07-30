#!/bin/sh -e

# Prevent execution if this script was only partially downloaded
{
# Detect operating system and set appropriate shell
OS=$(uname)
case "$OS" in
    Darwin)
        PLATFORM="macos"
        # Use bash on macOS for better compatibility
        if [ -z "$BASH_VERSION" ]; then
            exec /bin/bash "$0" "$@"
        fi
        ;;
    Linux)
        PLATFORM="linux"
        # Use sh on Linux for POSIX compliance
        ;;
    *)
        printf 'ERROR: Unsupported operating system: %s. This installer supports macOS and Linux only.\n' "$OS"
        exit 1
        ;;
esac

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

# Architecture detection (mainly for Linux, but also useful for future macOS ARM support)
findArch() {
    case "$(uname -m)" in
        x86_64|amd64) 
            arch="x86_64" 
            ;;
        aarch64|arm64) 
            arch="aarch64" 
            ;;
        armv7l) 
            arch="armv7l" 
            ;;
        *) 
            check 1 "Unsupported architecture: $(uname -m)"
            ;;
    esac
}

# Get download URL based on platform and architecture
getUrl() {
    if [ "$PLATFORM" = "macos" ]; then
        echo "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-macos"
    else
        # Linux
        case "${arch}" in
            x86_64) 
                echo "https://github.com/Jaredy899/osutil/releases/latest/download/osutil"
                ;;
            *) 
                echo "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-${arch}"
                ;;
        esac
    fi
}

# Detect architecture
findArch

printf 'Installing osutil for %s (%s)...\n' "$PLATFORM" "$arch"

temp_file=$(mktemp)
check $? "Creating the temporary file"

printf 'Downloading osutil for %s (%s)...\n' "$PLATFORM" "$arch"
curl -fsL "$(getUrl)" -o "$temp_file"
check $? "Downloading osutil"

chmod +x "$temp_file"
check $? "Making osutil executable"

# Remove quarantine attribute on macOS to avoid Gatekeeper warning
if [ "$PLATFORM" = "macos" ]; then
    xattr -d com.apple.quarantine "$temp_file" 2>/dev/null || true
fi

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