#!/bin/sh -e

. ../common-script.sh
. ./mise-common.sh

installBuildDependencies() {
    printf "%b\n" "${YELLOW}Installing Ruby build dependencies via Homebrew...${RC}"
    ensureHomebrewAvailable

    if ! xcode-select -p >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Installing Xcode Command Line Tools...${RC}"
        xcode-select --install
    fi

    brew install openssl@3 readline libyaml gmp autoconf rust
}

installRuby() {
    printf "%b\n" "${YELLOW}Installing Ruby via mise...${RC}"
    installBuildDependencies
    ensureMise
    mise use -g ruby@latest

    printf "%b\n" "${GREEN}Ruby installed via mise. Restart your shell or run: eval \"\$(mise activate zsh)\"${RC}"
    printf "%b\n" "${CYAN}Note: For YJIT support in Ruby 3.2+, Rust compiler has been installed.${RC}"
}

checkEnv
installRuby
