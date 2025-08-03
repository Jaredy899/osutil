#!/bin/sh -e

. ../../common-script.sh

installEPEL() {
    printf "%b\n" "${YELLOW}Installing EPEL repository...${RC}"
    
    case "$PACKAGER" in
        dnf)
            if [ "$DTYPE" = "fedora" ]; then
                printf "%b\n" "${YELLOW}EPEL is not needed on Fedora.${RC}"
                return 0
            fi
            
            # Check if EPEL is already installed
            if "$ESCALATION_TOOL" "$PACKAGER" repolist | grep -q "epel"; then
                printf "%b\n" "${GREEN}EPEL repository is already installed.${RC}"
                return 0
            fi
            
            # Install EPEL based on the distribution
            case "$DTYPE" in
                rhel|centos)
                    "$ESCALATION_TOOL" "$PACKAGER" install -y epel-release
                    ;;
                rocky)
                    "$ESCALATION_TOOL" "$PACKAGER" install -y epel-release
                    ;;
                almalinux)
                    "$ESCALATION_TOOL" "$PACKAGER" install -y epel-release
                    ;;
                *)
                    printf "%b\n" "${YELLOW}Unknown RHEL variant: $DTYPE${RC}"
                    printf "%b\n" "${YELLOW}Attempting to install EPEL anyway...${RC}"
                    "$ESCALATION_TOOL" "$PACKAGER" install -y epel-release
                    ;;
            esac
            
            # Refresh package cache
            "$ESCALATION_TOOL" "$PACKAGER" update
            
            printf "%b\n" "${GREEN}EPEL repository installed successfully.${RC}"
            ;;
        *)
            printf "%b\n" "${RED}EPEL is only available for RHEL-based systems using dnf.${RC}"
            exit 1
            ;;
    esac
}

checkEnv
checkEscalationTool
installEPEL 