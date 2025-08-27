#!/bin/sh -e

. ../common-script.sh

installZig() {
    printf "%b\n" "${YELLOW}Installing Zig...${RC}"

    # Ensure curl is available
    "$ESCALATION_TOOL" "$PACKAGER" install -y curl

    # Determine architecture and OS
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')

    # Map architecture names
    case "$ARCH" in
        x86_64) ARCH="x86_64" ;;
        aarch64) ARCH="aarch64" ;;
        *) printf "%b\n" "${RED}Unsupported architecture: $ARCH${RC}"; exit 1 ;;
    esac

    # Get latest Zig release info
    printf "%b\n" "${YELLOW}Fetching latest Zig release information...${RC}"
    LATEST_RELEASE=$(curl -fsSL https://api.github.com/repos/ziglang/zig/releases/latest)
    ZIG_VERSION=$(echo "$LATEST_RELEASE" | grep -o '"tag_name"[^,]*' | grep -o '[^"]*$' | sed 's/^v//')

    if [ -z "$ZIG_VERSION" ]; then
        printf "%b\n" "${RED}Failed to get latest Zig version${RC}"
        exit 1
    fi

    printf "%b\n" "${YELLOW}Latest Zig version: $ZIG_VERSION${RC}"

    # Check if already installed
    if command_exists zig; then
        CURRENT_VERSION=$(zig version 2>/dev/null | head -n1)
        if [ "$CURRENT_VERSION" = "$ZIG_VERSION" ]; then
            printf "%b\n" "${GREEN}Zig $ZIG_VERSION is already installed${RC}"
            return 0
        fi
    fi

    # Download and install Zig
    INSTALL_DIR="/usr/local/zig"
    TMP_DIR=$(mktemp -d)

    # Find the correct download URL
    DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep "browser_download_url.*${ARCH}-${OS}.*\.tar\.xz" | head -n1 | cut -d '"' -f 4)

    if [ -z "$DOWNLOAD_URL" ]; then
        printf "%b\n" "${RED}No suitable Zig download found for ${ARCH}-${OS}${RC}"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    printf "%b\n" "${YELLOW}Downloading Zig from: $DOWNLOAD_URL${RC}"

    # Download and extract
    cd "$TMP_DIR"
    curl -fsSL "$DOWNLOAD_URL" -o "zig.tar.xz"
    tar -xf "zig.tar.xz"

    # Find the extracted directory
    ZIG_DIR=$(find . -maxdepth 1 -type d -name "*" ! -name "." | head -n1 | sed 's|^\./||')

    if [ -z "$ZIG_DIR" ]; then
        printf "%b\n" "${RED}Failed to find extracted Zig directory${RC}"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    # Install to /usr/local/zig
    printf "%b\n" "${YELLOW}Installing Zig to $INSTALL_DIR${RC}"
    "$ESCALATION_TOOL" rm -rf "$INSTALL_DIR"
    "$ESCALATION_TOOL" mv "$ZIG_DIR" "$INSTALL_DIR"

    # Create symlink in /usr/local/bin
    "$ESCALATION_TOOL" ln -sf "$INSTALL_DIR/zig" /usr/local/bin/zig

    # Cleanup
    rm -rf "$TMP_DIR"

    # Verify installation
    if command_exists zig; then
        printf "%b\n" "${GREEN}Zig installed successfully!${RC}"
        printf "%b\n" "${CYAN}Zig version: $(zig version)${RC}"
        printf "%b\n" "${CYAN}Zig location: $INSTALL_DIR${RC}"
    else
        printf "%b\n" "${RED}Zig installation failed${RC}"
        exit 1
    fi
}

checkEnv
installZig
