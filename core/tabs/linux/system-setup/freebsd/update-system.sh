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
        
        # Check if portsnap is available
        if command_exists "portsnap"; then
            "$ESCALATION_TOOL" portsnap fetch update
        elif command_exists "git"; then
            # Alternative: use git to update ports tree
            printf "%b\n" "${YELLOW}portsnap not found, trying git method...${RC}"
            if [ -d /usr/ports/.git ]; then
                "$ESCALATION_TOOL" git -C /usr/ports pull
            else
                printf "%b\n" "${YELLOW}Ports tree is not a git repository, skipping update${RC}"
            fi
        else
            printf "%b\n" "${YELLOW}Neither portsnap nor git found, skipping ports tree update${RC}"
        fi
    fi

    printf "%b\n" "${GREEN}System update completed successfully!${RC}"
}

checkEnv
updateSystem
