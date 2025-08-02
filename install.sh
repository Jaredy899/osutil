#!/bin/sh

OS=$(uname)
ARCH=$(uname -m)

case "$OS" in
  Darwin)
    URL="https://github.com/Jaredy899/osutil/releases/latest/download/osutil-macos"
    ;;
  Linux)
    case "$ARCH" in
      x86_64|amd64)
        URL="https://github.com/Jaredy899/osutil/releases/latest/download/osutil"
        ;;
      aarch64|arm64)
        URL="https://github.com/Jaredy899/osutil/releases/latest/download/osutil-aarch64"
        ;;
      armv7l)
        URL="https://github.com/Jaredy899/osutil/releases/latest/download/osutil-armv7l"
        ;;
      *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
    esac
    ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

TMP=$(mktemp)
curl -fsSL "$URL" -o "$TMP"
chmod +x "$TMP"
[ "$OS" = "Darwin" ] && xattr -d com.apple.quarantine "$TMP" 2>/dev/null || true
"$TMP" "$@"
rm -f "$TMP"