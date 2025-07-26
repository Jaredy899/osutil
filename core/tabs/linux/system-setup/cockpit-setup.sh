#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

install_cockpit() {
    if ! command_exists cockpit; then
        printf "%b\n" "${YELLOW}Installing Cockpit...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm cockpit
                ;;
            apt-get|nala|dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y cockpit
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
                exit 1
                ;;
        esac
        startAndEnableService "cockpit.socket"
        printf "%b\n" "${GREEN}Cockpit service has been started.${RC}"
        printf "%b\n" "${GREEN}Cockpit installation complete.${RC}"
    else
        printf "%b\n" "${GREEN}Cockpit is already installed.${RC}"
    fi
}

configure_firewall() {
    if command_exists ufw; then
        "$ESCALATION_TOOL" ufw allow 9090/tcp
        "$ESCALATION_TOOL" ufw reload
        printf "%b\n" "${GREEN}UFW configuration updated to allow Cockpit.${RC}"
    elif command_exists firewall-cmd; then
        "$ESCALATION_TOOL" firewall-cmd --permanent --add-port=9090/tcp
        "$ESCALATION_TOOL" firewall-cmd --reload
        printf "%b\n" "${GREEN}Firewalld configuration updated to allow Cockpit.${RC}"
    else
        printf "%b\n" "${YELLOW}Neither UFW nor firewalld is installed. Please ensure port 9090 is open for Cockpit.${RC}"
    fi
    printf "%b\n" "${CYAN}You can access Cockpit via https://$(ip route get 1 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'):9090${RC}"
}

checkEnv
checkEscalationTool
install_cockpit
configure_firewall