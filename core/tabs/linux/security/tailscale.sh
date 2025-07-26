#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

installTailscale() {
    if ! command_exists tailscale; then
        printf "%b\n" "${YELLOW}Installing Tailscale...${RC}"
        case "$PACKAGER" in
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y tailscale
                startAndEnableService tailscaled
                printf "%b\n" "${GREEN}Tailscale installed successfully!${RC}"
                ;;
            *)
                curl -fsSL https://tailscale.com/install.sh | sh
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Tailscale is already installed${RC}"
    fi
}

configureTailscale() {
    printf "%b\n" "${YELLOW}Configuring Tailscale...${RC}"
    $ESCALATION_TOOL tailscale up
    printf "%b\n" "${GREEN}Tailscale configured successfully!${RC}"
}


checkEnv
checkEscalationTool
installTailscale
configureTailscale