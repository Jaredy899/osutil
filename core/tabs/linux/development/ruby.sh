#!/bin/sh -e

. ../common-script.sh

installBuildDependencies() {
    printf "%b\n" "${YELLOW}Installing Ruby build dependencies...${RC}"
    
    case "$PACKAGER" in
        apt-get|nala)
            printf "%b\n" "${YELLOW}Installing dependencies for Ubuntu/Debian/Mint...${RC}"
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y build-essential autoconf libssl-dev libyaml-dev zlib1g-dev libffi-dev libgmp-dev rustc
            # For older stable versions
            "$ESCALATION_TOOL" "$PACKAGER" install -y patch libreadline6-dev libncurses5-dev libgdbm6 libgdbm-dev libdb-dev || true
            ;;
        dnf)
            printf "%b\n" "${YELLOW}Installing dependencies for RHEL/CentOS/Fedora...${RC}"
            if command_exists dnf; then
                "$ESCALATION_TOOL" "$PACKAGER" install -y autoconf gcc rust patch make bzip2 openssl-devel libyaml-devel libffi-devel readline-devel gdbm-devel ncurses-devel perl-FindBin
                # Handle zlib for Fedora >= v40
                if "$ESCALATION_TOOL" "$PACKAGER" list zlib-ng-compat-devel >/dev/null 2>&1; then
                    "$ESCALATION_TOOL" "$PACKAGER" install -y zlib-ng-compat-devel
                else
                    "$ESCALATION_TOOL" "$PACKAGER" install -y zlib-devel
                fi
            else
                "$ESCALATION_TOOL" yum install -y autoconf gcc patch bzip2 openssl-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel tar
            fi
            ;;
        pacman)
            printf "%b\n" "${YELLOW}Installing dependencies for Arch Linux...${RC}"
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm base-devel rust libffi libyaml openssl zlib
            ;;
        apk)
            printf "%b\n" "${YELLOW}Installing dependencies for Alpine Linux...${RC}"
            "$ESCALATION_TOOL" "$PACKAGER" add build-base gcc6 patch bzip2 libffi-dev openssl-dev ncurses-dev gdbm-dev zlib-dev readline-dev yaml-dev rust
            ;;
        zypper)
            printf "%b\n" "${YELLOW}Installing dependencies for openSUSE...${RC}"
            "$ESCALATION_TOOL" "$PACKAGER" install -y gcc make rust patch automake bzip2 libopenssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel
            ;;
        eopkg)
            printf "%b\n" "${YELLOW}Installing dependencies for Solus...${RC}"
            "$ESCALATION_TOOL" "$PACKAGER" install -y autoconf gmp-devel libffi-devel rust openssl-devel yaml-devel zlib-ng-devel -c system.devel
            ;;
        pkg)
            printf "%b\n" "${YELLOW}Installing dependencies for FreeBSD...${RC}"
            "$ESCALATION_TOOL" "$PACKAGER" install -y autoconf gcc gmake rust patch bzip2 openssl libyaml libffi readline zlib gdbm ncurses
            ;;
        *)
            printf "%b\n" "${YELLOW}Unknown package manager, skipping build dependencies installation${RC}"
            ;;
    esac
}

installRuby() {
    printf "%b\n" "${YELLOW}Installing Ruby via mise...${RC}"

    # Install build dependencies first
    installBuildDependencies

    # Install mise if not available
    if ! command_exists mise; then
        printf "%b\n" "${YELLOW}Installing mise...${RC}"
        curl https://mise.run | sh
        # Source mise in current shell
        [ -f "$HOME/.local/share/mise/mise.sh" ] && . "$HOME/.local/share/mise/mise.sh"
    fi

    # Install latest stable Ruby
    mise use -g ruby@latest

    printf "%b\n" "${GREEN}Ruby installed via mise. Restart your shell or source your shell profile to use Ruby.${RC}"
    printf "%b\n" "${CYAN}Note: For YJIT support in Ruby 3.2+, Rust compiler has been installed.${RC}"
    
    # Troubleshooting guidance
    printf "%b\n" "${CYAN}Troubleshooting tips:${RC}"
    printf "%b\n" "${CYAN}- If compilation fails, ensure all build dependencies are installed${RC}"
    printf "%b\n" "${CYAN}- For 'C compiler cannot create executables' error, check build environment${RC}"
    printf "%b\n" "${CYAN}- For bigdecimal errors on macOS 14+, apply upstream patches${RC}"
    printf "%b\n" "${CYAN}- For Fedora 42+ and Ruby 3.1, use: RUBY_CFLAGS=\"-std=gnu17\" rbenv install <version>${RC}"
    printf "%b\n" "${CYAN}- For more help, see: https://github.com/rbenv/ruby-build/wiki${RC}"
}

checkEnv
installRuby


