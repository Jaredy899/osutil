#!/bin/sh -e

. ../common-script.sh

installGo() {
    printf "%b\n" "${YELLOW}Installing latest stable Go from official tarball...${RC}"

    VERSION=$(curl -fsSL https://go.dev/VERSION?m=text | head -n1)
    if [ -z "$VERSION" ]; then
        printf "%b\n" "${RED}Failed to fetch latest Go version.${RC}"
        exit 1
    fi

    case "$ARCH" in
        x86_64) GO_ARCH="amd64" ;;
        aarch64) GO_ARCH="arm64" ;;
        *) printf "%b\n" "${RED}Unsupported architecture for Go: $ARCH${RC}" ; exit 1 ;;
    esac

    TARBALL="${VERSION}.linux-${GO_ARCH}.tar.gz"
    URL="https://go.dev/dl/${TARBALL}"

    curl -fsSL "$URL" -o /tmp/go.tgz

    printf "%b\n" "${YELLOW}Removing any existing /usr/local/go...${RC}"
    "$ESCALATION_TOOL" rm -rf /usr/local/go

    printf "%b\n" "${YELLOW}Extracting Go to /usr/local...${RC}"
    "$ESCALATION_TOOL" tar -C /usr/local -xzf /tmp/go.tgz
    rm -f /tmp/go.tgz

    # Ensure PATH is set via profile.d
    PROFILE_SNIPPET="export PATH=\"/usr/local/go/bin:\$PATH\""
    if [ -w /etc/profile.d ] || [ "$ESCALATION_TOOL" != "eval" ]; then
        printf "%s\n" "$PROFILE_SNIPPET" | "$ESCALATION_TOOL" tee /etc/profile.d/go.sh > /dev/null || true
        "$ESCALATION_TOOL" chmod 644 /etc/profile.d/go.sh || true
    fi

    printf "%b\n" "${GREEN}Go ${VERSION#go} installed. Open a new shell or add /usr/local/go/bin to PATH for current session.${RC}"
}

checkEnv
installGo


