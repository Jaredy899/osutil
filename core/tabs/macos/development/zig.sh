#!/bin/sh -e

. ../common-script.sh
. ./mise-common.sh

installZig() {
    printf "%b\n" "${YELLOW}Installing Zig via mise...${RC}"
    ensureMise
    mise use -g zig@latest
    printf "%b\n" "${GREEN}Zig installed via mise. Restart your shell or run: eval \"\$(mise activate zsh)\"${RC}"
}

checkEnv
installZig
