#!/bin/sh -e

. ../../common-script.sh

installLynx() {
    if ! command_exists lynx; then
        printf "%b\n" "${YELLOW}Installing Lynx...${RC}"
        installPkg lynx
    else
        printf "%b\n" "${GREEN}Lynx TUI Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installLynx
