#!/bin/sh -e

. ../common-script.sh
. ./mise-common.sh

installGo() {
    printf "%b\n" "${YELLOW}Installing Go via mise...${RC}"
    ensureMise
    mise use -g go@latest
    printf "%b\n" "${GREEN}Go installed via mise. Restart your shell or run: eval \"\$(mise activate zsh)\"${RC}"
}

checkEnv
installGo
