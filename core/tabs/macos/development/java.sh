#!/bin/sh -e

. ../common-script.sh
. ./mise-common.sh

installJava() {
    printf "%b\n" "${YELLOW}Installing Java via mise...${RC}"
    ensureMise

    if mise ls-remote java 2>/dev/null | grep -q "21\."; then
        mise use -g java@21
    else
        mise use -g java@17
    fi

    printf "%b\n" "${GREEN}Java installed via mise. Restart your shell or run: eval \"\$(mise activate zsh)\"${RC}"
}

checkEnv
installJava
