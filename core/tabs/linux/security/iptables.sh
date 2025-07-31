#!/bin/sh -e

. ../common-script.sh

installPkg() {
    if ! command_exists iptables; then
        printf "%b\n" "${YELLOW}Installing iptables...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm iptables
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add iptables
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy iptables
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y iptables
                ;;
        esac
    else
        printf "%b\n" "${GREEN}iptables is already installed${RC}"
    fi
}

configureIptables() {
    printf "%b\n" "${YELLOW}Using Chris Titus Recommended Firewall Rules (iptables)${RC}"

    printf "%b\n" "${YELLOW}Flushing existing iptables rules${RC}"
    "$ESCALATION_TOOL" iptables -F
    "$ESCALATION_TOOL" iptables -X
    "$ESCALATION_TOOL" iptables -t nat -F
    "$ESCALATION_TOOL" iptables -t nat -X
    "$ESCALATION_TOOL" iptables -t mangle -F
    "$ESCALATION_TOOL" iptables -t mangle -X

    printf "%b\n" "${YELLOW}Setting default policies${RC}"
    "$ESCALATION_TOOL" iptables -P INPUT DROP
    "$ESCALATION_TOOL" iptables -P FORWARD DROP
    "$ESCALATION_TOOL" iptables -P OUTPUT ACCEPT

    printf "%b\n" "${YELLOW}Allowing established and related connections${RC}"
    "$ESCALATION_TOOL" iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    printf "%b\n" "${YELLOW}Limiting SSH (port 22/tcp)${RC}"
    "$ESCALATION_TOOL" iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
    "$ESCALATION_TOOL" iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
    "$ESCALATION_TOOL" iptables -A INPUT -p tcp --dport 22 -j ACCEPT

    printf "%b\n" "${YELLOW}Allowing HTTP (port 80/tcp)${RC}"
    "$ESCALATION_TOOL" iptables -A INPUT -p tcp --dport 80 -j ACCEPT

    printf "%b\n" "${YELLOW}Allowing HTTPS (port 443/tcp)${RC}"
    "$ESCALATION_TOOL" iptables -A INPUT -p tcp --dport 443 -j ACCEPT

    printf "%b\n" "${YELLOW}Allowing loopback interface${RC}"
    "$ESCALATION_TOOL" iptables -A INPUT -i lo -j ACCEPT

    printf "%b\n" "${GREEN}Enabled Firewall with Baselines! (iptables)${RC}"
}

checkEnv
checkEscalationTool
installPkg
configureIptables