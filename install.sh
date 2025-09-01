#!/bin/sh

# Color support (POSIX compliant)
RC='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PURPLE='\033[35m'
CYAN='\033[36m'
BOLD='\033[1m'

# Check if colors should be used
use_colors() {
    # Use colors if stdout is a terminal and TERM is set (not 'dumb')
    [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ]
}

# Starting message
if use_colors; then
    printf "%b\n" "${CYAN}${BOLD}Starting OSutil${RC}"
else
    printf "Starting OSutil\n"
fi

OS=$(uname)
ARCH=$(uname -m)

case "$OS" in
  Darwin)
    case "$ARCH" in
      x86_64|amd64)
        URL="https://github.com/Jaredy899/osutil/releases/latest/download/osutil-macos-x86_64"
        ;;
      arm64|aarch64)
        URL="https://github.com/Jaredy899/osutil/releases/latest/download/osutil-macos-arm64"
        ;;
      *)
        if use_colors; then
            printf "%b\n" "${RED}Unsupported macOS architecture: $ARCH${RC}"
        else
            printf "Unsupported macOS architecture: %s\n" "$ARCH"
        fi
        exit 1
        ;;
    esac
    ;;
  Linux)
    case "$ARCH" in
      x86_64|amd64)
        URL="https://github.com/Jaredy899/osutil/releases/latest/download/osutil-linux-x86_64"
        ;;
      aarch64|arm64)
        URL="https://github.com/Jaredy899/osutil/releases/latest/download/osutil-linux-aarch64"
        ;;
      armv7l)
        URL="https://github.com/Jaredy899/osutil/releases/latest/download/osutil-linux-armv7"
        ;;
      *)
        if use_colors; then
            printf "%b\n" "${RED}Unsupported architecture: $ARCH${RC}"
        else
            printf "Unsupported architecture: %s\n" "$ARCH"
        fi
        exit 1
        ;;
    esac
    ;;
  FreeBSD)
    case "$ARCH" in
      x86_64|amd64)
        URL="https://github.com/Jaredy899/osutil/releases/latest/download/osutil-freebsd-x86_64"
        ;;
      *)
        if use_colors; then
            printf "%b\n" "${RED}Unsupported FreeBSD architecture: $ARCH${RC}"
        else
            printf "Unsupported FreeBSD architecture: %s\n" "$ARCH"
        fi
        exit 1
        ;;
    esac
    ;;
  *)
    if use_colors; then
        printf "%b\n" "${RED}Unsupported OS: $OS${RC}"
    else
        printf "Unsupported OS: %s\n" "$OS"
    fi
    exit 1
    ;;
esac

TMP=$(mktemp)
curl -fsSL "$URL" -o "$TMP"
chmod +x "$TMP"
[ "$OS" = "Darwin" ] && xattr -d com.apple.quarantine "$TMP" 2>/dev/null || true
"$TMP" "$@"
rm -f "$TMP"