#!/bin/sh -e
#
# Manage AerynOS moss repositories (volatile for packaging, local for build artifacts).
# https://aerynos.dev/packaging/workflow/basic-workflow/
#

. ../../common-script.sh

checkAeryn() {
    if [ "$PACKAGER" != "moss" ]; then
        printf "%b\n" "${RED}This script is for AerynOS (moss). Current packager: ${PACKAGER}${RC}"
        exit 1
    fi
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" != "aerynos" ] && [ "${ID#aeryn}" = "$ID" ]; then
            if ! command_exists moss 2>/dev/null; then
                printf "%b\n" "${RED}This script is for AerynOS. Detected OS: ${ID:-unknown}${RC}"
                exit 1
            fi
        fi
    fi
}

listRepos() {
    printf "%b\n" "${CYAN}=== Moss repositories ===${RC}"
    "$PACKAGER" repo list
}

enablePackagingRepos() {
    printf "%b\n" "${YELLOW}Enabling volatile and local (for packaging/testing). Volatile can be unstable; disable when not packaging.${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" repo enable volatile 2>/dev/null || true
    "$ESCALATION_TOOL" "$PACKAGER" repo enable local 2>/dev/null || true
    "$ESCALATION_TOOL" "$PACKAGER" sync -u
    printf "%b\n" "${GREEN}Volatile and local enabled; sync done.${RC}"
}

disablePackagingRepos() {
    printf "%b\n" "${YELLOW}Disabling volatile and local.${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" repo disable volatile 2>/dev/null || true
    "$ESCALATION_TOOL" "$PACKAGER" repo disable local 2>/dev/null || true
    "$ESCALATION_TOOL" "$PACKAGER" sync -u
    printf "%b\n" "${GREEN}Volatile and local disabled; sync done.${RC}"
}

syncRepos() {
    printf "%b\n" "${YELLOW}Syncing repository indices...${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" sync -u
    printf "%b\n" "${GREEN}Done.${RC}"
}

runChoice() {
    printf "%b\n" "${CYAN}Volatile/Local: enable / disable / list / sync${RC}"
    printf "%b" "${CYAN}Choice [list]: ${RC}"
    read -r choice
    [ -z "$choice" ] && choice="list"
    case "$choice" in
        enable|Enable|ENABLE)
            enablePackagingRepos
            ;;
        disable|Disable|DISABLE)
            disablePackagingRepos
            ;;
        list|List|LIST)
            listRepos
            ;;
        sync|Sync|SYNC)
            syncRepos
            ;;
        *)
            printf "%b\n" "${YELLOW}Unknown option. Showing repos.${RC}"
            listRepos
            ;;
    esac
}

checkEnv
checkEscalationTool
checkAeryn
runChoice
