#!/bin/sh -e

. ../common-script.sh

installBuildDependencies() {
    printf "%b\n" "${YELLOW}Installing Ruby build dependencies via Homebrew...${RC}"
    
    # Ensure Homebrew is available (common-script.sh handles installation)
    ensureHomebrewAvailable

    # Install Xcode Command Line Tools if not present
    if ! xcode-select -p >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Installing Xcode Command Line Tools...${RC}"
        xcode-select --install
    fi

    # Install build dependencies
    printf "%b\n" "${YELLOW}Installing OpenSSL, readline, libyaml, gmp, autoconf, and Rust...${RC}"
    brew install openssl@3 readline libyaml gmp autoconf rust

    # Note about OpenSSL 1.1 for older Ruby versions
    printf "%b\n" "${CYAN}Note: For Ruby 3.0 and older, you may need OpenSSL 1.1:${RC}"
    printf "%b\n" "${CYAN}  brew install rbenv/tap/openssl@1.1${RC}"
    printf "%b\n" "${CYAN}  RUBY_CONFIGURE_OPTS=\"--with-openssl-dir=\$(brew --prefix openssl@1.1)\" rbenv install <version>${RC}"
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
    printf "%b\n" "${CYAN}To enable YJIT: ruby-build 3.2.2 /opt/rubies/ruby-3.2.2 -- --enable-yjit${RC}"
    
    # Troubleshooting guidance
    printf "%b\n" "${CYAN}Troubleshooting tips:${RC}"
    printf "%b\n" "${CYAN}- If compilation fails, ensure all build dependencies are installed${RC}"
    printf "%b\n" "${CYAN}- For bigdecimal errors on macOS 14+, apply upstream patches${RC}"
    printf "%b\n" "${CYAN}- For Apple Silicon issues, ensure Homebrew is in /opt/homebrew${RC}"
    printf "%b\n" "${CYAN}- Avoid GNU binutils from Homebrew (brew unlink binutils if needed)${RC}"
    printf "%b\n" "${CYAN}- For Anaconda conflicts, deactivate conda: conda deactivate${RC}"
    printf "%b\n" "${CYAN}- For more help, see: https://github.com/rbenv/ruby-build/wiki${RC}"
}

checkEnv
installRuby


