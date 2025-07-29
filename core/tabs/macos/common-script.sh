#!/bin/sh -e

# shellcheck disable=SC2034

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
GREEN='\033[32m'

command_exists() {
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || return 1
    done
    return 0
}

brewprogram_exists() {
    for cmd in "$@"; do
        brew list "$cmd" >/dev/null 2>&1 || return 1
    done
    return 0
}

setup_askpass() {
    # Create a temporary askpass helper script
    ASKPASS_SCRIPT="/tmp/osutil_askpass_$$"
    cat > "$ASKPASS_SCRIPT" << 'EOF'
#!/bin/sh
osascript -e 'display dialog "Administrator password required for OSutil setup:" default answer "" with hidden answer' -e 'text returned of result' 2>/dev/null
EOF
    chmod +x "$ASKPASS_SCRIPT"
    export SUDO_ASKPASS="$ASKPASS_SCRIPT"
}

cleanup_askpass() {
    # Clean up the temporary askpass script
    if [ -n "$ASKPASS_SCRIPT" ] && [ -f "$ASKPASS_SCRIPT" ]; then
        rm -f "$ASKPASS_SCRIPT"
    fi
}

checkPackageManager() {
    if command_exists "brew"; then
        printf "%b\n" "${GREEN}Homebrew is installed${RC}"
    else
        printf "%b\n" "${RED}Homebrew is not installed${RC}"
        printf "%b\n" "${YELLOW}Installing Homebrew...${RC}"

        setup_askpass
        trap cleanup_askpass EXIT INT TERM

        NONINTERACTIVE=1 sudo -A /bin/bash -c \
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        install_result=$?

        if [ $install_result -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Homebrew${RC}"
            exit 1
        fi

        # Add Homebrew to PATH for the current session
        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -f "/usr/local/bin/brew" ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
}

checkCurrentDirectoryWritable() {
    GITPATH="$(dirname "$(realpath "$0")")"
    if [ ! -w "$GITPATH" ]; then
        printf "%b\n" "${RED}Can't write to $GITPATH${RC}"
        exit 1
    fi
}

checkEnv() {
    checkPackageManager
}