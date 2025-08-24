#!/bin/sh -e

. ../common-script.sh

installFirefox() {
    printf "%b\n" "${YELLOW}Installing Firefox...${RC}"

    # Install Firefox
    printf "%b\n" "${CYAN}Installing Firefox browser...${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" install -y firefox

    printf "%b\n" "${GREEN}Firefox installed successfully!${RC}"
    printf "%b\n" "${CYAN}You can launch Firefox from the Applications menu or by running 'firefox'${RC}"
}

checkEnv
installFirefox
