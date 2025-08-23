#!/bin/sh -e

. ../common-script.sh

installPortsTree() {
    printf "%b\n" "${YELLOW}Installing FreeBSD ports tree...${RC}"

    # Check if ports tree already exists
    if [ -d /usr/ports ]; then
        printf "%b\n" "${CYAN}Ports tree already exists at /usr/ports${RC}"
        printf "%b\n" "${YELLOW}Updating existing ports tree...${RC}"
        "$ESCALATION_TOOL" portsnap fetch update
    else
        printf "%b\n" "${CYAN}Installing ports tree...${RC}"
        "$ESCALATION_TOOL" portsnap fetch extract
    fi

    printf "%b\n" "${GREEN}Ports tree installed/updated successfully!${RC}"
    printf "%b\n" "${CYAN}You can now install packages from ports using: cd /usr/ports/category/package && make install clean${RC}"
}

checkEnv
installPortsTree
