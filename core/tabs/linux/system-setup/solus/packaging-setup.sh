#!/bin/sh -e
#
# Prepares a Solus system for packaging work per the official guide:
# https://help.getsol.us/docs/packaging/prepare-for-packaging
# Covers: packager file, dev tools, solbuild, optional repo clone + hooks + helpers.
#

. ../../common-script.sh

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
    printf "%b\n" "${CYAN}Solus detected. Preparing packaging environment.${RC}"
}

SOLUS_DEV_PACKAGES="ent git github-cli go-task intltool jq solbuild solbuild-config-unstable ypkg yq"

installDevTools() {
    printf "%b\n" "${CYAN}=== Installing Solus packaging development tools ===${RC}"
    case "$PACKAGER" in
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y $SOLUS_DEV_PACKAGES
            printf "%b\n" "${GREEN}Development tools installed.${RC}"
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager for Solus packaging: $PACKAGER${RC}"
            exit 1
            ;;
    esac
}

setupPackagerFile() {
    printf "%b\n" "${CYAN}=== Solus packager file (~/.config/solus/packager) ===${RC}"
    SOLUS_CONFIG_DIR="${HOME}/.config/solus"
    PACKAGER_FILE="${SOLUS_CONFIG_DIR}/packager"

    if [ -f "$PACKAGER_FILE" ]; then
        printf "%b\n" "${YELLOW}Packager file already exists.${RC}"
        printf "%b" "${CYAN}Overwrite? [y/N]: ${RC}"
        read -r overwrite
        case "$overwrite" in
            [Yy]*) ;;
            *) printf "%b\n" "${CYAN}Skipping packager file.${RC}"; return 0 ;;
        esac
    fi

    mkdir -p "$SOLUS_CONFIG_DIR"
    printf "%b\n" "${CYAN}Enter your full name (real first and last for accountability): ${RC}"
    read -r packager_name
    printf "%b\n" "${CYAN}Enter your email address: ${RC}"
    read -r packager_email
    printf "%b\n" "${CYAN}Matrix contact (optional, e.g. @user:matrix.org) [skip]: ${RC}"
    read -r packager_matrix

    {
        echo "[Packager]"
        echo "Name=$packager_name"
        echo "Email=$packager_email"
        [ -n "$packager_matrix" ] && echo "Matrix=$packager_matrix"
    } > "$PACKAGER_FILE"
    chmod 600 "$PACKAGER_FILE"
    printf "%b\n" "${GREEN}Packager file written to ${PACKAGER_FILE}${RC}"
}

setupGitAndGh() {
    printf "%b\n" "${CYAN}=== GitHub and Git ===${RC}"
    if ! gh auth status 2>/dev/null; then
        printf "%b\n" "${YELLOW}Run 'gh auth login' to authenticate with GitHub (required for submitting patches).${RC}"
        printf "%b" "${CYAN}Run gh auth login now? [Y/n]: ${RC}"
        read -r run_gh
        case "$run_gh" in
            [Nn]*) printf "%b\n" "${YELLOW}Remember to run: gh auth login${RC}" ;;
            *) gh auth login ;;
        esac
    else
        printf "%b\n" "${GREEN}GitHub CLI is already authenticated.${RC}"
    fi
    if command_exists gh && gh auth status 2>/dev/null; then
        gh auth setup-git 2>/dev/null || true
    fi
    if [ -z "$(git config --global user.name 2>/dev/null)" ] || [ -z "$(git config --global user.email 2>/dev/null)" ]; then
        printf "%b\n" "${YELLOW}Set Git identity if you have not already:${RC}"
        printf "%b\n" "${CYAN}  git config --global user.name \"Your Name\"${RC}"
        printf "%b\n" "${CYAN}  git config --global user.email your.email@address${RC}"
    fi
}

setupSolbuild() {
    printf "%b\n" "${CYAN}=== solbuild ===${RC}"
    if ! command_exists solbuild; then
        printf "%b\n" "${RED}solbuild not found. Install dev tools first.${RC}"
        return 1
    fi
    if [ ! -d /var/lib/solbuild/base-x86_64 ] && [ ! -d /var/lib/solbuild/base-aarch64 ]; then
        printf "%b\n" "${YELLOW}Initializing solbuild (downloads base image; may take a while)...${RC}"
        "$ESCALATION_TOOL" solbuild init
        printf "%b\n" "${GREEN}solbuild initialized.${RC}"
    else
        printf "%b\n" "${CYAN}solbuild base image already present.${RC}"
    fi
    printf "%b\n" "${YELLOW}Updating solbuild base image...${RC}"
    "$ESCALATION_TOOL" solbuild update
    printf "%b\n" "${GREEN}solbuild ready.${RC}"
}

cloneAndInitRepo() {
    printf "%b\n" "${CYAN}=== Fork and clone getsolus/packages ===${RC}"
    printf "%b\n" "${CYAN}Fork https://github.com/getsolus/packages on GitHub (or with: gh repo fork getsolus/packages).${RC}"
    printf "%b" "${CYAN}Clone your fork to this directory? Enter path [${HOME}/solus-packages]: ${RC}"
    read -r clone_path
    [ -z "$clone_path" ] && clone_path="${HOME}/solus-packages"

    if [ -d "$clone_path" ] && [ -d "$clone_path/.git" ]; then
        printf "%b\n" "${CYAN}Directory already exists and is a git repo. Initializing hooks only.${RC}"
        SOLUS_PACKAGES_DIR="$clone_path"
    else
        if [ -d "$clone_path" ]; then
            printf "%b\n" "${RED}Path exists and is not a git repo: $clone_path${RC}"
            return 1
        fi
        if command_exists gh && gh auth status 2>/dev/null; then
            printf "%b\n" "${YELLOW}Cloning your fork (gh repo clone packages) to $clone_path ...${RC}"
            gh repo clone packages "$clone_path"
            SOLUS_PACKAGES_DIR="$clone_path"
        else
            printf "%b\n" "${YELLOW}Not authenticated with gh. Clone manually: gh repo clone packages $clone_path${RC}"
            return 0
        fi
    fi

    if [ -n "$SOLUS_PACKAGES_DIR" ] && [ -d "$SOLUS_PACKAGES_DIR" ] && command_exists go-task; then
        printf "%b\n" "${YELLOW}Initializing git hooks for linting (go-task init)...${RC}"
        go-task -d "$SOLUS_PACKAGES_DIR" init
        printf "%b\n" "${GREEN}Git hooks initialized.${RC}"

        printf "%b" "${CYAN}Set up repository helper functions (gotopkg, gotosoluspkgs, etc.) for your shell? [y/N]: ${RC}"
        read -r setup_helpers
        case "$setup_helpers" in
            [Yy]*)
                setupHelperFunctions "$SOLUS_PACKAGES_DIR"
                ;;
            *)
                printf "%b\n" "${CYAN}Skip helpers. See: https://help.getsol.us/docs/packaging/prepare-for-packaging#set-up-repository-helper-functions-optional${RC}"
                ;;
        esac
    fi
}

setupHelperFunctions() {
    repo_dir="$1"
    helpers_sh="${repo_dir}/common/Scripts/helpers.sh"
    helpers_fish="${repo_dir}/common/Scripts/helpers.fish"
    helpers_zsh=""
    for f in "${repo_dir}/common/Scripts/helpers.zsh" "${repo_dir}/common/Scripts/solus-monorepo-helpers.zsh"; do
        [ -f "$f" ] && helpers_zsh="$f" && break
    done
    if [ ! -f "$helpers_sh" ]; then
        printf "%b\n" "${YELLOW}Helper scripts not found in repo (missing common/Scripts/helpers.*).${RC}"
        return 0
    fi
    printf "%b\n" "${CYAN}Shell: 1) bash  2) fish  3) zsh  4) skip${RC}"
    printf "%b" "${CYAN}Choice [1]: ${RC}"
    read -r shell_choice
    [ -z "$shell_choice" ] && shell_choice=1
    case "$shell_choice" in
        1)
            mkdir -p "${HOME}/.bashrc.d"
            chmod 700 "${HOME}/.bashrc.d"
            ln -sf "$helpers_sh" "${HOME}/dotfiles/bash/.bashrc.d/80-solus-monorepo-helpers.sh"
            printf "%b\n" "${GREEN}Bash: added ${HOME}/dotfiles/bash/.bashrc.d/80-solus-monorepo-helpers.sh. Source ~/.bashrc or open a new shell.${RC}"
            ;;
        2)
            if [ -f "$helpers_fish" ]; then
                mkdir -p "${HOME}/.config/fish/conf.d"
                ln -sf "$helpers_fish" "${HOME}/dotfiles/fish/.config/fish/conf.d/80-solus-monorepo-helpers.fish"
                printf "%b\n" "${GREEN}Fish: added ${HOME}/dotfiles/fish/.config/fish/conf.d/80-solus-monorepo-helpers.fish. Start a new fish shell.${RC}"
            else
                printf "%b\n" "${YELLOW}Fish helpers not found.${RC}"
            fi
            ;;
        3)
            if [ -f "$helpers_zsh" ]; then
                mkdir -p "${HOME}/.zshrc.d"
                chmod 700 "${HOME}/.zshrc.d"
                if ! grep -q 'solus-monorepo-helpers' "${HOME}/dotfiles/zsh/.zshrc" 2>/dev/null; then
                    printf "%b\n" "fpath=(\$HOME/.zshrc.d \$fpath)\nautoload -U \$HOME/.zshrc.d/*\nsource \$HOME/.zshrc.d/solus-monorepo-helpers.zsh" >> "${HOME}/dotfiles/zsh/.zshrc"
                fi
                ln -sf "$helpers_zsh" "${HOME}/dotfiles/zsh/.zshrc.d/80-solus-monorepo-helpers.zsh"
                printf "%b\n" "${GREEN}Zsh: added ${HOME}/dotfiles/zsh/.zshrc.d/80-solus-monorepo-helpers.zsh. Source ~/.zshrc or open a new shell.${RC}"
            else
                printf "%b\n" "${YELLOW}Zsh helpers not found.${RC}"
            fi
            ;;
        *)
            printf "%b\n" "${CYAN}Helpers skipped.${RC}"
            ;;
    esac
}

checkEnv
checkSolus
installDevTools
setupPackagerFile
setupGitAndGh
setupSolbuild
cloneAndInitRepo
