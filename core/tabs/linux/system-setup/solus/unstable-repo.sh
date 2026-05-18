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
    "$PACKAGER" list-repo 2>/dev/null | grep -q "^${UNSTABLE_NAME}"
}

addUnstable() {
    if hasUnstable; then
        printf "%b\n" "${CYAN}Unstable repo is already added.${RC}"
        return 0
    fi
    printf "%b\n" "${YELLOW}Adding Unstable repo. Updating on Unstable can be risky; check #solus-packaging on Matrix before system updates.${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" add-repo "$UNSTABLE_NAME" "$UNSTABLE_URL"
    "$ESCALATION_TOOL" "$PACKAGER" update-repo "$UNSTABLE_NAME"
    printf "%b\n" "${GREEN}Unstable repo added and updated.${RC}"
}

removeUnstable() {
    if ! hasUnstable; then
        printf "%b\n" "${CYAN}Unstable repo is not added.${RC}"
        return 0
    fi
    printf "%b\n" "${YELLOW}Removing Unstable repo.${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" remove-repo "$UNSTABLE_NAME"
    printf "%b\n" "${GREEN}Unstable repo removed.${RC}"
}

listRepos() {
    printf "%b\n" "${CYAN}=== Repositories ===${RC}"
    "$PACKAGER" list-repo
}

updateRepos() {
    printf "%b\n" "${YELLOW}Updating all repositories...${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" update-repo
    printf "%b\n" "${GREEN}Done.${RC}"
}

runChoice() {
    printf "%b\n" "${YELLOW}Solus Unstable repository:${RC}"
    printf "%b\n" "1. ${CYAN}Add Unstable repository${RC}"
    printf "%b\n" "2. ${CYAN}Remove Unstable repository${RC}"
    printf "%b\n" "3. ${CYAN}List repositories${RC}"
    printf "%b\n" "4. ${CYAN}Update all repositories${RC}"
    printf "%b" "Enter your choice [1-4]: "
    read -r choice
    [ -z "$choice" ] && choice=3
    case "$choice" in
        1)
            addUnstable
            ;;
        2)
            removeUnstable
            ;;
        3)
            listRepos
            ;;
        4)
            updateRepos
            ;;
        *)
            printf "%b\n" "${RED}Invalid choice. Showing repositories.${RC}"
            listRepos
            ;;
    esac
}

checkEnv
checkEscalationTool
checkSolus
runChoice
