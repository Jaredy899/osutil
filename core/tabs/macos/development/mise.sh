#!/bin/sh -e

. ../common-script.sh
. ./mise-common.sh

installMiseSetup() {
    printf "%b\n" "${CYAN}=== Mise (polyglot toolchain manager) ===${RC}"
    ensureHomebrewAvailable
    ensureMise
    symlinkMiseConfig

    printf "%b\n" "${GREEN}Mise is ready.${RC}"
    printf "%b\n" "${CYAN}Add this to your shell rc if it is not already present:${RC}"
    printf "%b\n" "  eval \"\$(mise activate zsh)\""
    printf "%b\n" "${CYAN}Then install languages from the Development tab (Node, Rust, Go, …).${RC}"
}

checkEnv
installMiseSetup
