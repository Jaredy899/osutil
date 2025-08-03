#!/bin/sh -e

. ../../common-script.sh

configureSELinux() {
    printf "%b\n" "${YELLOW}Configuring SELinux...${RC}"
    
    case "$PACKAGER" in
        dnf)
            if [ "$DTYPE" = "fedora" ]; then
                printf "%b\n" "${YELLOW}This script is optimized for RHEL-based systems.${RC}"
            fi
            
            # Check if SELinux is installed and enabled
            if ! command_exists sestatus; then
                printf "%b\n" "${YELLOW}SELinux is not installed. Installing...${RC}"
                "$ESCALATION_TOOL" "$PACKAGER" install -y policycoreutils
            fi
            
            if ! sestatus 2>/dev/null | grep -q "SELinux status:\s*enabled"; then
                printf "%b\n" "${YELLOW}SELinux is not enabled. This script will help configure it.${RC}"
            fi
            
            printf "%b\n" "${YELLOW}Choose SELinux configuration:${RC}"
            printf "%b\n" "1. ${CYAN}Enforcing${RC} - Default security policy (recommended)"
            printf "%b\n" "2. ${CYAN}Permissive${RC} - Log violations but don't block"
            printf "%b\n" "3. ${CYAN}Disabled${RC} - Turn off SELinux (not recommended)"
            printf "%b\n" "4. ${CYAN}Install common SELinux tools${RC}"
            printf "%b\n" "5. ${CYAN}Exit${RC}"
            printf "%b" "Enter your choice [1-5]: "
            read -r choice
            
            case "$choice" in
                1)
                    printf "%b\n" "${YELLOW}Setting SELinux to Enforcing mode...${RC}"
                    "$ESCALATION_TOOL" setenforce 1
                    "$ESCALATION_TOOL" sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
                    printf "%b\n" "${GREEN}SELinux set to Enforcing mode${RC}"
                    ;;
                2)
                    printf "%b\n" "${YELLOW}Setting SELinux to Permissive mode...${RC}"
                    "$ESCALATION_TOOL" setenforce 0
                    "$ESCALATION_TOOL" sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
                    printf "%b\n" "${GREEN}SELinux set to Permissive mode${RC}"
                    ;;
                3)
                    printf "%b\n" "${YELLOW}Setting SELinux to Disabled mode...${RC}"
                    "$ESCALATION_TOOL" setenforce 0
                    "$ESCALATION_TOOL" sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
                    printf "%b\n" "${YELLOW}SELinux will be disabled after reboot${RC}"
                    ;;
                4)
                    printf "%b\n" "${YELLOW}Installing SELinux management tools...${RC}"
                    "$ESCALATION_TOOL" "$PACKAGER" install -y policycoreutils-python-utils setools-console
                    printf "%b\n" "${GREEN}SELinux tools installed${RC}"
                    printf "%b\n" "${CYAN}Useful commands:${RC}"
                    printf "%b\n" "${CYAN}  - sestatus${RC} - Check SELinux status"
                    printf "%b\n" "${CYAN}  - getenforce${RC} - Get current mode"
                    printf "%b\n" "${CYAN}  - setsebool${RC} - Set boolean values"
                    printf "%b\n" "${CYAN}  - audit2allow${RC} - Generate policy from audit logs"
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
            printf "%b\n" "${RED}SELinux configuration is primarily for RHEL-based systems.${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
configureSELinux 