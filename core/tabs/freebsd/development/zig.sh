#!/bin/sh -e

. ../common-script.sh

installZig() {
    printf "%b\n" "${YELLOW}Installing Zig...${RC}"

    # Ensure curl is available
    "$ESCALATION_TOOL" "$PACKAGER" install -y curl

    # Determine architecture
    ARCH=$(uname -m)

    # Map architecture names
    case "$ARCH" in
        x86_64|amd64) ARCH="x86_64" ;;
        aarch64) ARCH="aarch64" ;;
        *) printf "%b\n" "${RED}Unsupported architecture: $ARCH${RC}"; exit 1 ;;
    esac

    # Get latest Zig release info using ziglang.org index
    printf "%b\n" "${YELLOW}Fetching latest Zig release information...${RC}"

    # Ensure jq is available for robust JSON parsing
    if ! command_exists jq; then
        printf "%b\n" "${YELLOW}Installing jq for JSON parsing...${RC}"
        "$ESCALATION_TOOL" "$PACKAGER" install -y jq
    fi

    # Fetch the official Zig download index
    if ! INDEX_JSON=$(curl -fsSL https://ziglang.org/download/index.json 2>/dev/null) || [ -z "$INDEX_JSON" ]; then
        printf "%b\n" "${RED}Failed to fetch Zig download index${RC}"
        exit 1
    fi

    # Extract the latest version number
    ZIG_VERSION=$(printf "%s" "$INDEX_JSON" | jq -r '
      to_entries
      | map(select(.key | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")))
      | sort_by(.key | split(".") | map(tonumber))
      | reverse
      | .[0].key' 2>/dev/null)

    if [ -z "$ZIG_VERSION" ]; then
        printf "%b\n" "${RED}Failed to parse latest Zig version${RC}"
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

    # Try FreeBSD-specific download first
    ZIG_KEY="${ARCH}-freebsd"
    DOWNLOAD_URL=$(printf "%s" "$INDEX_JSON" | jq -r --arg key "$ZIG_KEY" '
      [ to_entries
        | map(select(.key | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")))
        | sort_by(.key | split(".") | map(tonumber))
        | reverse[]
        | (.value[$key].tarball // .value.tarball)
      ]
      | map(select(. != null))
      | .[0] // empty')

    # If no FreeBSD download found, try Linux as fallback (often works on FreeBSD)
    if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
        printf "%b\n" "${YELLOW}No FreeBSD download found, trying Linux fallback...${RC}"
        ZIG_KEY="${ARCH}-linux"
        DOWNLOAD_URL=$(printf "%s" "$INDEX_JSON" | jq -r --arg key "$ZIG_KEY" '
          [ to_entries
            | map(select(.key | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")))
            | sort_by(.key | split(".") | map(tonumber))
            | reverse[]
            | (.value[$key].tarball // .value.tarball)
          ]
          | map(select(. != null))
          | .[0] // empty')
    fi

    # Last resort: use master (dev) only if no stable tarball found
    if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
        printf "%b\n" "${YELLOW}No stable release found, trying master (dev) version...${RC}"
        DOWNLOAD_URL=$(printf "%s" "$INDEX_JSON" | jq -r --arg key "$ZIG_KEY" '.master[$key].tarball // empty')
    fi

    if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
        printf "%b\n" "${RED}Failed to resolve a Zig download URL from index.json${RC}"
        printf "%b\n" "${YELLOW}Available platforms in latest release:${RC}"
        printf "%s" "$INDEX_JSON" | jq -r 'to_entries | map(select(.key | test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))) | sort_by(.key | split(".") | map(tonumber)) | reverse | .[0].value | keys[]' 2>/dev/null || echo "Could not parse available platforms"
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
