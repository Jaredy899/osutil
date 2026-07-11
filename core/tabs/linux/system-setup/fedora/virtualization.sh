#!/bin/sh -e

. ../../common-script.sh

# Install virtualization tools to enable virtual machines
configureVirtualization() {
    case "$PACKAGER" in
        dnf)
            printf "%b\n" "${YELLOW}Installing virtualization tools...${RC}"
            installPkg @virtualization
            printf "%b\n" "${GREEN}Installed virtualization tools...${RC}"
            ;;
        *)
            unsupportedPackager
            ;;
    esac
}

checkEnv
checkEscalationTool
configureVirtualization
