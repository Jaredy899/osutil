#!/bin/sh -e

. ../common-script.sh

installPortsTree() {
    printf "%b\n" "${YELLOW}Installing FreeBSD ports tree...${RC}"

    # Check if ports tree already exists
    if [ -d /usr/ports ]; then
        printf "%b\n" "${CYAN}Ports tree already exists at /usr/ports${RC}"
        printf "%b\n" "${YELLOW}Updating existing ports tree...${RC}"
        
        # Check if portsnap is available
        if command_exists "portsnap"; then
            "$ESCALATION_TOOL" portsnap fetch update
        elif command_exists "git"; then
            # Alternative: use git to update ports tree
            printf "%b\n" "${YELLOW}portsnap not found, trying git method...${RC}"
            if [ -d /usr/ports/.git ]; then
                "$ESCALATION_TOOL" git -C /usr/ports pull
            else
                printf "%b\n" "${YELLOW}Ports tree is not a git repository, trying to convert...${RC}"
                "$ESCALATION_TOOL" git clone https://git.freebsd.org/ports.git /usr/ports.tmp
                "$ESCALATION_TOOL" rm -rf /usr/ports
                "$ESCALATION_TOOL" mv /usr/ports.tmp /usr/ports
            fi
        elif command_exists "svn"; then
            # Alternative: use svn to update ports tree
            printf "%b\n" "${YELLOW}portsnap not found, trying svn method...${RC}"
            if [ -d /usr/ports/.svn ]; then
                "$ESCALATION_TOOL" svn update /usr/ports
            else
                printf "%b\n" "${YELLOW}Ports tree is not an svn repository, trying to convert...${RC}"
                "$ESCALATION_TOOL" svn checkout https://svn.freebsd.org/ports/head /usr/ports
            fi
        else
            printf "%b\n" "${RED}Neither portsnap, git, nor svn found. Cannot update ports tree.${RC}"
            printf "%b\n" "${YELLOW}Please install portsnap: pkg install portsnap${RC}"
            exit 1
        fi
    else
        printf "%b\n" "${CYAN}Installing ports tree...${RC}"
        
        # Check if portsnap is available
        if command_exists "portsnap"; then
            "$ESCALATION_TOOL" portsnap fetch extract
        elif command_exists "git"; then
            # Alternative: use git to install ports tree
            printf "%b\n" "${YELLOW}portsnap not found, using git method...${RC}"
            "$ESCALATION_TOOL" git clone https://git.freebsd.org/ports.git /usr/ports
        elif command_exists "svn"; then
            # Alternative: use svn to install ports tree
            printf "%b\n" "${YELLOW}portsnap not found, using svn method...${RC}"
            "$ESCALATION_TOOL" svn checkout https://svn.freebsd.org/ports/head /usr/ports
        else
            printf "%b\n" "${RED}Neither portsnap, git, nor svn found. Cannot install ports tree.${RC}"
            printf "%b\n" "${YELLOW}Please install portsnap: pkg install portsnap${RC}"
            exit 1
        fi
    fi

    printf "%b\n" "${GREEN}Ports tree installed/updated successfully!${RC}"
    printf "%b\n" "${CYAN}You can now install packages from ports using: cd /usr/ports/category/package && make install clean${RC}"
}

checkEnv
installPortsTree
