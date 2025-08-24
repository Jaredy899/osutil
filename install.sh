#!/bin/sh

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
        echo "Unsupported macOS architecture: $ARCH"
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
        echo "Unsupported architecture: $ARCH"
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
        echo "Unsupported FreeBSD architecture: $ARCH"
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