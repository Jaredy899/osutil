#!/bin/sh

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${CYAN}Starting OSutil${NC}"

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
        echo -e "${RED}❌ Unsupported macOS architecture: $ARCH${NC}"
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
        echo -e "${RED}❌ Unsupported architecture: $ARCH${NC}"
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
        echo -e "${RED}❌ Unsupported FreeBSD architecture: $ARCH${NC}"
        exit 1
        ;;
    esac
    ;;
  *)
    echo -e "${RED}❌ Unsupported OS: $OS${NC}"
    exit 1
    ;;
esac

TMP=$(mktemp)
curl -fsSL "$URL" -o "$TMP"
chmod +x "$TMP"
[ "$OS" = "Darwin" ] && xattr -d com.apple.quarantine "$TMP" 2>/dev/null || true
"$TMP" "$@"
rm -f "$TMP"