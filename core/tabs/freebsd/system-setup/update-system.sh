#!/bin/sh -e

. ../common-script.sh

updateSystem() {
    printf "%b\n" "${YELLOW}Updating FreeBSD system...${RC}"

    # Update package database
    printf "%b\n" "${CYAN}Updating package database...${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" update

    # Upgrade all packages
    printf "%b\n" "${CYAN}Upgrading packages...${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" upgrade -y

    # Clean up old packages
    printf "%b\n" "${CYAN}Cleaning up old packages...${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" autoremove -y

    # Update ports tree if available
    if [ "$PORTS_AVAILABLE" = "true" ]; then
        printf "%b\n" "${CYAN}Updating ports tree...${RC}"
        "$ESCALATION_TOOL" portsnap fetch update
    fi

    printf "%b\n" "${GREEN}System update completed successfully!${RC}"
}

checkEnv
updateSystem
