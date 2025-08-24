#!/bin/sh -e

# shellcheck disable=SC2034

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
GREEN='\033[32m'
MAGENTA='\033[35m'

command_exists() {
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || return 1
    done
    return 0
}

checkArch() {
    case "$(uname -m)" in
        amd64 | x86_64) ARCH="amd64" ;;
        aarch64 | arm64) ARCH="aarch64" ;;
        armv7) ARCH="armv7" ;;
        i386 | i686) ARCH="i386" ;;
        *) printf "%b\n" "${RED}Unsupported architecture: $(uname -m)${RC}" && exit 1 ;;
    esac

    printf "%b\n" "${CYAN}System architecture: ${ARCH}${RC}"
}

checkEscalationTool() {
    ## Check for escalation tools.
    if [ -z "$ESCALATION_TOOL_CHECKED" ]; then
        if [ "$(id -u)" = "0" ]; then
            ESCALATION_TOOL="eval"
            ESCALATION_TOOL_CHECKED=true
            printf "%b\n" "${CYAN}Running as root, no escalation needed${RC}"
            return 0
        fi

        ESCALATION_TOOLS='sudo doas'
        for tool in ${ESCALATION_TOOLS}; do
            if command_exists "${tool}"; then
                ESCALATION_TOOL=${tool}
                printf "%b\n" "${CYAN}Using ${tool} for privilege escalation${RC}"
                ESCALATION_TOOL_CHECKED=true
                return 0
            fi
        done

        printf "%b\n" "${RED}Can't find a supported escalation tool${RC}"
        exit 1
    fi
}

checkCommandRequirements() {
    ## Check for requirements.
    REQUIREMENTS=$1
    MISSING_REQS=""
    for req in ${REQUIREMENTS}; do
        if ! command_exists "${req}"; then
            MISSING_REQS="$MISSING_REQS $req"
        fi
    done
    if [ -n "$MISSING_REQS" ]; then
        printf "%b\n" "${YELLOW}Missing requirements:${MISSING_REQS}${RC}"
        return 1
    fi
    return 0
}

checkPackageManager() {
    ## Check Package Manager - FreeBSD uses pkg
    if command_exists "pkg"; then
        PACKAGER="pkg"
        printf "%b\n" "${CYAN}Using pkg as package manager${RC}"
    else
        printf "%b\n" "${RED}pkg package manager not found${RC}"
        printf "%b\n" "${YELLOW}Installing pkg...${RC}"
        "$ESCALATION_TOOL" pkg bootstrap
        if command_exists "pkg"; then
            PACKAGER="pkg"
            printf "%b\n" "${GREEN}pkg installed successfully${RC}"
        else
            printf "%b\n" "${RED}Failed to install pkg${RC}"
            exit 1
        fi
    fi

    # Update package database
    "$ESCALATION_TOOL" "$PACKAGER" update
}

checkSuperUser() {
    ## Check SuperUser Group - FreeBSD uses wheel
    if groups | grep -q "wheel"; then
        SUGROUP="wheel"
        printf "%b\n" "${CYAN}Super user group: wheel${RC}"
    else
        printf "%b\n" "${RED}You need to be a member of the wheel group to run me!${RC}"
        exit 1
    fi
}

checkCurrentDirectoryWritable() {
    ## Check if the current directory is writable.
    GITPATH="$(dirname "$(realpath "$0")")"
    if [ ! -w "$GITPATH" ]; then
        printf "%b\n" "${RED}Can't write to $GITPATH${RC}"
        exit 1
    fi
}

checkFreeBSDVersion() {
    ## Check FreeBSD version
    if [ -f /etc/version ]; then
        FREEBSD_VERSION=$(head -n1 /etc/version | cut -d' ' -f2)
        printf "%b\n" "${CYAN}FreeBSD version: ${FREEBSD_VERSION}${RC}"
    else
        printf "%b\n" "${YELLOW}Could not determine FreeBSD version${RC}"
    fi
}

checkPortsTree() {
    ## Check if ports tree is available
    if [ -d /usr/ports ]; then
        printf "%b\n" "${CYAN}Ports tree available at /usr/ports${RC}"
        PORTS_AVAILABLE=true
    else
        printf "%b\n" "${YELLOW}Ports tree not found at /usr/ports${RC}"
        PORTS_AVAILABLE=false
    fi
}

checkEnv() {
    checkArch
    checkEscalationTool
    checkCommandRequirements "curl groups $ESCALATION_TOOL"
    checkPackageManager
    checkCurrentDirectoryWritable
    checkSuperUser
    checkFreeBSDVersion
    checkPortsTree
}
