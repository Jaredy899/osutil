#!/bin/sh -e

. ../../common-script.sh

installSlack() {
    if ! command_exists com.slack.Slack && ! command_exists slack; then
        printf "%b\n" "${YELLOW}Installing Slack...${RC}"
        case "$PACKAGER" in
            pacman)
                installAurPkg slack-desktop
                ;;
            *)
                installFlatpak com.slack.Slack
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Slack is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installSlack
