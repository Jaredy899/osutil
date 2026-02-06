#!/bin/sh -e
#
# Manage Solus Unstable repository (for packaging or testing).
# https://help.getsol.us/docs/user/package-management/repo-management
#

. ../../common-script.sh

UNSTABLE_NAME="Unstable"
UNSTABLE_URL="https://cdn.getsol.us/repo/unstable/eopkg-index.xml.xz"

checkSolus() {
    if [ "$PACKAGER" != "eopkg" ]; then
        printf "%b\n" "${RED}This script is for Solus (eopkg). Current packager: ${PACKAGER}${RC}"
        exit 1
    fi
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" != "solus" ] && [ "${ID#solus}" = "$ID" ]; then
            if ! command_exists eopkg 2>/dev/null; then
                printf "%b\n" "${RED}This script is for Solus. Detected OS: ${ID:-unknown}${RC}"
                exit 1
            fi
        fi
    fi
}

hasUnstable() {
    $PACKAGER list-repo 2>/dev/null | grep -q "^${UNSTABLE_NAME}"
}

addUnstable() {
    if hasUnstable; then
        printf "%b\n" "${CYAN}Unstable repo is already added.${RC}"
        return 0
    fi
    printf "%b\n" "${YELLOW}Adding Unstable repo. Updating on Unstable can be risky; check #solus-packaging on Matrix before system updates.${RC}"
    "$ESCALATION_TOOL" $PACKAGER add-repo "$UNSTABLE_NAME" "$UNSTABLE_URL"
    "$ESCALATION_TOOL" $PACKAGER update-repo "$UNSTABLE_NAME"
    printf "%b\n" "${GREEN}Unstable repo added and updated.${RC}"
}

removeUnstable() {
    if ! hasUnstable; then
        printf "%b\n" "${CYAN}Unstable repo is not added.${RC}"
        return 0
    fi
    printf "%b\n" "${YELLOW}Removing Unstable repo.${RC}"
    "$ESCALATION_TOOL" $PACKAGER remove-repo "$UNSTABLE_NAME"
    printf "%b\n" "${GREEN}Unstable repo removed.${RC}"
}

listRepos() {
    printf "%b\n" "${CYAN}=== Repositories ===${RC}"
    $PACKAGER list-repo
}

updateRepos() {
    printf "%b\n" "${YELLOW}Updating all repositories...${RC}"
    "$ESCALATION_TOOL" $PACKAGER update-repo
    printf "%b\n" "${GREEN}Done.${RC}"
}

runChoice() {
    printf "%b\n" "${CYAN}Unstable repo: add / remove / list / update-all${RC}"
    printf "%b" "${CYAN}Choice [list]: ${RC}"
    read -r choice
    [ -z "$choice" ] && choice="list"
    case "$choice" in
        add|Add|ADD)
            addUnstable
            ;;
        remove|Remove|REMOVE)
            removeUnstable
            ;;
        list|List|LIST)
            listRepos
            ;;
        update|update-all|Update)
            updateRepos
            ;;
        *)
            printf "%b\n" "${YELLOW}Unknown option. Showing repos.${RC}"
            listRepos
            ;;
    esac
}

checkEnv
checkEscalationTool
checkSolus
runChoice
