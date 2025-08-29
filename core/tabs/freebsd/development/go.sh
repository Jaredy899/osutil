#!/bin/sh -e

. ../common-script.sh

installGo() {
    printf "%b\n" "${YELLOW}Installing Go from official tarball...${RC}"

    # Ensure curl and tar are available
    "$ESCALATION_TOOL" "$PACKAGER" install -y curl gtar

    # Get latest Go version
    GO_VERSION=$(curl -fsSL https://go.dev/VERSION?m=text | head -n1)
    if [ -z "$GO_VERSION" ]; then
        printf "%b\n" "${RED}Could not determine latest Go version${RC}"
        exit 1
    fi

    printf "%b\n" "${CYAN}Installing Go version: ${GO_VERSION}${RC}"

    # Download and install Go
    cd /tmp
    curl -LO "https://golang.org/dl/${GO_VERSION}.freebsd-${ARCH}.tar.gz"
    
    if [ ! -f "${GO_VERSION}.freebsd-${ARCH}.tar.gz" ]; then
        printf "%b\n" "${RED}Failed to download Go tarball${RC}"
        exit 1
    fi

    # Remove existing Go installation if it exists
    "$ESCALATION_TOOL" rm -rf /usr/local/go

    # Extract to /usr/local
    "$ESCALATION_TOOL" tar -C /usr/local -xzf "${GO_VERSION}.freebsd-${ARCH}.tar.gz"

    # Clean up
    rm -f "${GO_VERSION}.freebsd-${ARCH}.tar.gz"

    # Add Go to PATH for current session
    export PATH="/usr/local/go/bin:$PATH"

    # Ensure Go is in PATH for future sessions
    if ! grep -q "/usr/local/go/bin" "$HOME/.bashrc" 2>/dev/null; then
        {
            printf "%s\n" ''
            printf "%s\n" "export PATH=\"/usr/local/go/bin:\$PATH\""
        } >> "$HOME/.bashrc"
    fi

    printf "%b\n" "${GREEN}Go installed successfully!${RC}"
    printf "%b\n" "${CYAN}Go version: $(go version)${RC}"
}

checkEnv
installGo
