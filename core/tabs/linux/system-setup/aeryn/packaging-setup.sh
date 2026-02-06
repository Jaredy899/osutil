#!/bin/sh -e
#
# Prepares AerynOS for packaging per the official workflow:
# https://aerynos.dev/packaging/workflow/
# Covers: build-essential, clone recipes, helpers, just init, subuid/subgid,
# optional local repo + boulder profile + moss repos (volatile/local).
#

. ../../common-script.sh

AERYNOS_RECIPES_URL="https://github.com/AerynOS/recipes"
VOLATILE_URI="https://build.aerynos.dev/volatile/x86_64/stone.index"
LOCAL_URI="file://${HOME}/.cache/local_repo/x86_64/stone.index"
AERYNOS_RECIPES_DIR="${HOME}/repos/aerynos/recipes"

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
    printf "%b\n" "${CYAN}AerynOS detected. Preparing packaging environment.${RC}"
}

installBuildEssential() {
    printf "%b\n" "${CYAN}=== Installing build-essential ===${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" sync -u
    "$ESCALATION_TOOL" "$PACKAGER" install -y build-essential
    printf "%b\n" "${GREEN}build-essential installed (includes just, boulder, etc.).${RC}"
}

cloneAndSetupHelpers() {
    printf "%b\n" "${CYAN}=== Clone AerynOS recipes and activate helpers ===${RC}"
    REPOS_BASE="${HOME}/repos/aerynos"
    RECIPES_DIR="${REPOS_BASE}/recipes"
    printf "%b" "${CYAN}Recipes clone path [${RECIPES_DIR}]: ${RC}"
    read -r clone_path
    [ -z "$clone_path" ] && clone_path="$RECIPES_DIR"

    if [ -d "$clone_path" ] && [ -d "$clone_path/.git" ]; then
        printf "%b\n" "${CYAN}Recipes repo already present at ${clone_path}.${RC}"
        RECIPES_DIR="$clone_path"
        AERYNOS_RECIPES_DIR="$clone_path"
    else
        mkdir -p "$(dirname "$clone_path")"
        if [ -d "$clone_path" ]; then
            printf "%b\n" "${RED}Path exists and is not a git repo: $clone_path${RC}"
            return 1
        fi
        printf "%b\n" "${YELLOW}Cloning AerynOS/recipes to ${clone_path} ...${RC}"
        git clone "$AERYNOS_RECIPES_URL" "$clone_path"
        RECIPES_DIR="$clone_path"
        AERYNOS_RECIPES_DIR="$clone_path"
    fi

    HELPERS_BASH="${RECIPES_DIR}/tools/helpers.bash"
    if [ ! -f "$HELPERS_BASH" ]; then
        printf "%b\n" "${RED}Helpers not found: ${HELPERS_BASH}${RC}"
        return 1
    fi

    BASHRC_D="${HOME}/dotfiles/bash/.bashrc.d"
    mkdir -p "$BASHRC_D"
    chmod 700 "$BASHRC_D"
    ln -sf "$HELPERS_BASH" "${BASHRC_D}/90-aerynos-helpers.bash"
    AERYNOS_RECIPES_DIR="$RECIPES_DIR"
    printf "%b\n" "${GREEN}Symlinked helpers to ${BASHRC_D}/90-aerynos-helpers.bash. Source ~/.bashrc or open a new shell, then run: gotoaosrepo${RC}"
}

setupJustInit() {
    printf "%b\n" "${CYAN}=== Git hooks and linters (just init) ===${RC}"
    [ -d "${AERYNOS_RECIPES_DIR}/.git" ] || return 0
    if command_exists just; then
        (cd "$AERYNOS_RECIPES_DIR" && just init)
        printf "%b\n" "${GREEN}Git hooks and commit templates set up.${RC}"
    else
        printf "%b\n" "${YELLOW}just not found. Run installBuildEssential first, then: cd ${AERYNOS_RECIPES_DIR} && just init${RC}"
    fi
}

setupGitMossDiff() {
    printf "%b\n" "${CYAN}=== Git diff for manifest.*.bin (moss inspect) ===${RC}"
    [ -d "${AERYNOS_RECIPES_DIR}/.git" ] || return 0
    if ! git -C "$AERYNOS_RECIPES_DIR" config --get diff.moss.textconv >/dev/null 2>&1; then
        git -C "$AERYNOS_RECIPES_DIR" config 'diff.moss.textconv' 'moss inspect'
        git -C "$AERYNOS_RECIPES_DIR" config 'diff.moss.binary' 'true'
        printf "%b\n" "${GREEN}Git moss diff configured.${RC}"
    else
        printf "%b\n" "${CYAN}moss diff already configured.${RC}"
    fi
}

setupGitGoneAlias() {
    printf "%b\n" "${CYAN}=== Git 'gone' alias (prune deleted remote branches) ===${RC}"
    if ! git config --global --get alias.gone >/dev/null 2>&1; then
        git config --global alias.gone '!f() { git fetch --all --prune; git branch -vv | awk '\''/: gone]/{print $1}'\'' | xargs git branch -D; }; f'
        printf "%b\n" "${GREEN}Git alias 'gone' added.${RC}"
    else
        printf "%b\n" "${CYAN}alias.gone already set.${RC}"
    fi
}

setupSubuidSubgid() {
    printf "%b\n" "${CYAN}=== /etc/subuid and /etc/subgid (for boulder) ===${RC}"
    if [ ! -f /etc/subuid ]; then
        "$ESCALATION_TOOL" touch /etc/subuid
    fi
    if [ ! -f /etc/subgid ]; then
        "$ESCALATION_TOOL" touch /etc/subgid
    fi
    "$ESCALATION_TOOL" usermod --add-subuids 1000000-1065535 --add-subgids 1000000-1065535 root 2>/dev/null || true
    "$ESCALATION_TOOL" usermod --add-subuids 1065536-1131071 --add-subgids 1065536-1131071 "$USER" 2>/dev/null || true
    printf "%b\n" "${GREEN}subuid/subgid entries configured.${RC}"
}

createLocalRepoAndMossRepos() {
    printf "%b\n" "${CYAN}=== Local repo and moss volatile/local ===${RC}"
    if [ ! -d "$AERYNOS_RECIPES_DIR" ] || ! command_exists just; then
        printf "%b\n" "${YELLOW}Skip: clone recipes and install build-essential first.${RC}"
        return 0
    fi
    printf "%b" "${CYAN}Create local repo and add volatile/local to moss? [y/N]: ${RC}"
    read -r do_it
    case "$do_it" in
        [Yy]*)
            (cd "$AERYNOS_RECIPES_DIR" && just create-local && just index-local)
            if ! "$PACKAGER" repo list 2>/dev/null | grep -q "volatile"; then
                "$ESCALATION_TOOL" "$PACKAGER" repo add volatile "$VOLATILE_URI" -p 10
            fi
            if ! "$PACKAGER" repo list 2>/dev/null | grep -q "local"; then
                "$ESCALATION_TOOL" "$PACKAGER" repo add local "$LOCAL_URI" -p 100
            fi
            printf "%b\n" "${YELLOW}Add boulder profile for local builds: boulder profile add --reponame=volatile,uri=${VOLATILE_URI},priority=0 --reponame=local,uri=${LOCAL_URI},priority=100 local-x86_64${RC}"
            printf "%b\n" "${GREEN}Local repo created; volatile and local moss repos added. Enable with: sudo moss repo enable volatile; sudo moss repo enable local; sudo moss sync -u${RC}"
            ;;
        *)
            printf "%b\n" "${CYAN}Skipped. See https://aerynos.dev/packaging/workflow/basic-workflow/${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
checkAeryn
installBuildEssential
cloneAndSetupHelpers
setupJustInit
setupGitMossDiff
setupGitGoneAlias
setupSubuidSubgid
createLocalRepoAndMossRepos
