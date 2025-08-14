#!/bin/sh -e

. ../common-script.sh

installGo() {
    printf "%b\n" "${YELLOW}Installing Go (via Homebrew)...${RC}"
    if ! brew install go; then
        printf "%b\n" "${RED}Failed to install Go with Homebrew.${RC}"
        exit 1
    fi
    printf "%b\n" "${GREEN}Go installed. Verify with: go version${RC}"
}

checkEnv
installGo


