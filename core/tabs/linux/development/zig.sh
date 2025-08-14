#!/bin/sh -e

. ../common-script.sh

installZig() {
    printf "%b\n" "${YELLOW}Installing latest stable Zig...${RC}"

    case "$ARCH" in
        x86_64) ZIG_ARCH="x86_64" ;;
        aarch64) ZIG_ARCH="aarch64" ;;
        *) printf "%b\n" "${RED}Unsupported architecture for Zig: $ARCH${RC}" ; exit 1 ;;
    esac

    INDEX_JSON=$(curl -fsSL https://ziglang.org/download/index.json)
    STABLE_VER=$(printf "%s" "$INDEX_JSON" | grep -o '"stable"[^"]*"[^"]\+"' | head -n1 | sed 's/.*"stable"[^"]*"\([^"]\+\)".*/\1/')
    if [ -z "$STABLE_VER" ]; then
        # Fallback: first semantic version key
        STABLE_VER=$(printf "%s" "$INDEX_JSON" | grep -o '"[0-9]\+\.[0-9]\+\.[0-9]\+"' | head -n1 | tr -d '"')
    fi

    if [ -z "$STABLE_VER" ]; then
        printf "%b\n" "${RED}Failed to determine latest stable Zig version.${RC}"
        exit 1
    fi

    PKG="zig-linux-${ZIG_ARCH}-${STABLE_VER}.tar.xz"
    URL="https://ziglang.org/download/${STABLE_VER}/${PKG}"

    curl -fsSL "$URL" -o "/tmp/${PKG}"

    DEST_DIR="/opt/zig"
    EXTRACTED_DIR="${DEST_DIR}/zig-linux-${ZIG_ARCH}-${STABLE_VER}"

    "$ESCALATION_TOOL" mkdir -p "$DEST_DIR"
    # Remove any existing dir for this version/arch
    "$ESCALATION_TOOL" rm -rf "$EXTRACTED_DIR"

    printf "%b\n" "${YELLOW}Extracting Zig to ${DEST_DIR}...${RC}"
    "$ESCALATION_TOOL" tar -C "$DEST_DIR" -xJf "/tmp/${PKG}"
    rm -f "/tmp/${PKG}"

    # Symlink /usr/local/bin/zig
    "$ESCALATION_TOOL" mkdir -p /usr/local/bin
    "$ESCALATION_TOOL" ln -sf "${EXTRACTED_DIR}/zig" /usr/local/bin/zig

    printf "%b\n" "${GREEN}Zig ${STABLE_VER} installed. You can run 'zig version' to verify.${RC}"
}

checkEnv
installZig


