#!/bin/sh -e

. ../../common-script.sh

installAlternativeRepos() {
    printf "%b\n" "${YELLOW}Installing alternative repositories for RHEL...${RC}"
    
    case "$PACKAGER" in
        dnf)
            if [ "$DTYPE" = "fedora" ]; then
                printf "%b\n" "${YELLOW}This script is for RHEL-based systems. Use the Fedora repository scripts instead.${RC}"
                return 0
            fi
            
            # Get RHEL version
            rhel_version=$(rpm -E %rhel 2>/dev/null || echo "8")
            
            printf "%b\n" "${YELLOW}Choose repositories to install:${RC}"
            printf "%b\n" "1. ${CYAN}PowerTools/CodeReady Builder${RC} - Development tools and libraries"
            printf "%b\n" "2. ${CYAN}Remi Repository${RC} - PHP and web technologies"
            printf "%b\n" "3. ${CYAN}EPEL Next${RC} - Newer packages from EPEL"
            printf "%b\n" "4. ${CYAN}All of the above${RC}"
            printf "%b\n" "5. ${CYAN}Exit${RC}"
            printf "%b" "Enter your choice [1-5]: "
            read -r choice
            
            case "$choice" in
                1)
                    installPowerTools "$rhel_version"
                    ;;
                2)
                    installRemi "$rhel_version"
                    ;;
                3)
                    installEPELNext "$rhel_version"
                    ;;
                4)
                    installPowerTools "$rhel_version"
                    installRemi "$rhel_version"
                    installEPELNext "$rhel_version"
                    ;;
                5)
                    printf "%b\n" "${GREEN}Exiting.${RC}"
                    exit 0
                    ;;
                *)
                    printf "%b\n" "${RED}Invalid choice. Exiting.${RC}"
                    exit 1
                    ;;
            esac
            ;;
        *)
            printf "%b\n" "${RED}Alternative repositories are primarily for RHEL-based systems.${RC}"
            ;;
    esac
}

installPowerTools() {
    rhel_version="$1"
    printf "%b\n" "${YELLOW}Installing PowerTools/CodeReady Builder repository...${RC}"
    
    if [ "$rhel_version" -ge 8 ]; then
        # For RHEL 8+, enable CodeReady Builder
        if "$ESCALATION_TOOL" "$PACKAGER" repolist | grep -q "codeready-builder"; then
            "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled "codeready-builder-for-rhel-${rhel_version}-$(arch)-rpms"
            printf "%b\n" "${GREEN}CodeReady Builder repository enabled${RC}"
        else
            printf "%b\n" "${YELLOW}CodeReady Builder repository not found. It may require a Red Hat subscription.${RC}"
        fi
    else
        # For older versions, try PowerTools
        if "$ESCALATION_TOOL" "$PACKAGER" repolist | grep -q "powertools"; then
            "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled powertools
            printf "%b\n" "${GREEN}PowerTools repository enabled${RC}"
        else
            printf "%b\n" "${YELLOW}PowerTools repository not found${RC}"
        fi
    fi
}

installRemi() {
    rhel_version="$1"
    printf "%b\n" "${YELLOW}Installing Remi repository...${RC}"
    
    # Install Remi repository
    "$ESCALATION_TOOL" "$PACKAGER" install -y "https://rpms.remirepo.net/enterprise/remi-release-${rhel_version}.rpm"
    
    # Import GPG key
    "$ESCALATION_TOOL" rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-remi
    
    printf "%b\n" "${GREEN}Remi repository installed${RC}"
    printf "%b\n" "${CYAN}Note: Use 'dnf module list php' to see available PHP versions${RC}"
    printf "%b\n" "${CYAN}Use 'dnf module enable php:remi-8.1' to enable a specific PHP version${RC}"
}

installEPELNext() {
    rhel_version="$1"
    printf "%b\n" "${YELLOW}Installing EPEL Next repository...${RC}"
    
    # Install EPEL Next
    "$ESCALATION_TOOL" "$PACKAGER" install -y "https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-${rhel_version}.noarch.rpm"
    
    printf "%b\n" "${GREEN}EPEL Next repository installed${RC}"
    printf "%b\n" "${CYAN}Note: EPEL Next contains newer packages but may be less stable${RC}"
}

checkEnv
checkEscalationTool
installAlternativeRepos 