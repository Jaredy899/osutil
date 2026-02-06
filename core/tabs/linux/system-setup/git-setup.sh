#!/bin/sh -e

. ../common-script.sh

checkGitInstalled() {
    if ! command_exists git; then
        printf "%b\n" "${YELLOW}Git is not installed. Installing git...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm git
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add git
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy git
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y git
                ;;
        esac
        printf "%b\n" "${GREEN}Git installed successfully.${RC}"
    else
        printf "%b\n" "${CYAN}Git is already installed.${RC}"
    fi
}

checkGhInstalled() {
    if ! command_exists gh; then
        printf "%b\n" "${YELLOW}GitHub CLI (gh) is not installed. Installing gh...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm gh
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add github-cli
                ;;
            eopkg|moss)
                "$ESCALATION_TOOL" "$PACKAGER" install -y github-cli
                ;;
             xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy gh
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gh
                ;;
        esac
        printf "%b\n" "${GREEN}GitHub CLI installed successfully.${RC}"
    else
        printf "%b\n" "${CYAN}GitHub CLI is already installed.${RC}"
    fi
}

setupGitWithGh() {
    printf "%b\n" "${CYAN}=== GitHub CLI Git Setup ===${RC}"
    if ! gh auth status 2>/dev/null; then
        printf "%b\n" "${YELLOW}Not logged in to GitHub. Running 'gh auth login'...${RC}"
        gh auth login
    fi
    if gh auth status 2>/dev/null; then
        gh auth setup-git
        printf "%b\n" "${GREEN}Git configured to use GitHub CLI for credentials and identity.${RC}"
        return 0
    else
        printf "%b\n" "${RED}GitHub authentication failed or was cancelled.${RC}"
        return 1
    fi
}

maybeSetupWithGh() {
    printf "%b\n" "${CYAN}=== GitHub CLI Option ===${RC}"
    printf "%b" "${CYAN}Use GitHub CLI (gh) to set up Git credentials and identity? [y/N]: ${RC}"
    read -r use_gh_response
    case "$use_gh_response" in
        [Yy]*)
            checkGhInstalled
            if setupGitWithGh; then
                USE_GH=true
            fi
            ;;
        *)
            printf "%b\n" "${CYAN}Using manual Git configuration.${RC}"
            ;;
    esac
}

configureGit() {
    printf "%b\n" "${YELLOW}Configuring Git...${RC}"
    
    # Get current git config values as defaults
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")
    current_editor=$(git config --global core.editor 2>/dev/null || echo "")
    current_branch=$(git config --global init.defaultBranch 2>/dev/null || echo "main")
    current_eol=$(git config --global core.autocrlf 2>/dev/null || echo "")
    current_pull_rebase=$(git config --global pull.rebase 2>/dev/null || echo "false")
    
    # Skip username/email if already configured via gh
    if [ "$USE_GH" != true ]; then
        # Prompt for username
        printf "%b\n" "${CYAN}=== Git User Configuration ===${RC}"
        if [ -n "$current_name" ]; then
            printf "%b" "${CYAN}Enter your Git username [${current_name}]: ${RC}"
        else
            printf "%b" "${CYAN}Enter your Git username: ${RC}"
        fi
        read -r git_username
        if [ -z "$git_username" ] && [ -n "$current_name" ]; then
            git_username="$current_name"
        fi
        if [ -n "$git_username" ]; then
            git config --global user.name "$git_username"
            printf "%b\n" "${GREEN}Git username set to: ${git_username}${RC}"
        fi
        
        # Prompt for email
        if [ -n "$current_email" ]; then
            printf "%b" "${CYAN}Enter your Git email [${current_email}]: ${RC}"
        else
            printf "%b" "${CYAN}Enter your Git email: ${RC}"
        fi
        read -r git_email
        if [ -z "$git_email" ] && [ -n "$current_email" ]; then
            git_email="$current_email"
        fi
        if [ -n "$git_email" ]; then
            git config --global user.email "$git_email"
            printf "%b\n" "${GREEN}Git email set to: ${git_email}${RC}"
        fi
    else
        printf "%b\n" "${CYAN}User name and email configured via GitHub CLI.${RC}"
    fi
    
    # Prompt for default editor
    printf "%b\n" "${CYAN}=== Git Editor Configuration ===${RC}"
    printf "%b\n" "${CYAN}Common editors: vim, nano, code, nvim, emacs${RC}"
    if [ -n "$current_editor" ]; then
        printf "%b" "${CYAN}Enter your preferred Git editor [${current_editor}]: ${RC}"
    else
        printf "%b" "${CYAN}Enter your preferred Git editor: ${RC}"
    fi
    read -r git_editor
    if [ -z "$git_editor" ] && [ -n "$current_editor" ]; then
        git_editor="$current_editor"
    fi
    if [ -n "$git_editor" ]; then
        git config --global core.editor "$git_editor"
        printf "%b\n" "${GREEN}Git editor set to: ${git_editor}${RC}"
    fi
    
    # Prompt for default branch name
    printf "%b\n" "${CYAN}=== Git Branch Configuration ===${RC}"
    printf "%b" "${CYAN}Enter default branch name for new repositories [${current_branch}]: ${RC}"
    read -r git_branch
    if [ -z "$git_branch" ]; then
        git_branch="$current_branch"
    fi
    if [ -n "$git_branch" ]; then
        git config --global init.defaultBranch "$git_branch"
        printf "%b\n" "${GREEN}Default branch name set to: ${git_branch}${RC}"
    fi
    
    # Prompt for line ending preferences
    printf "%b\n" "${CYAN}=== Git Line Ending Configuration ===${RC}"
    printf "%b\n" "${CYAN}Options:${RC}"
    printf "%b\n" "${CYAN}  input - Use LF for commits (recommended for Linux/Mac)${RC}"
    printf "%b\n" "${CYAN}  true - Auto convert CRLF to LF on commit, LF to CRLF on checkout (Windows)${RC}"
    printf "%b\n" "${CYAN}  false - No conversion (not recommended)${RC}"
    
    if [ -z "$current_eol" ]; then
        current_eol="input"
    fi
    printf "%b" "${CYAN}Enter line ending preference (input/true/false) [${current_eol}]: ${RC}"
    read -r git_eol
    if [ -z "$git_eol" ]; then
        git_eol="$current_eol"
    fi
    case "$git_eol" in
        input|true|false)
            git config --global core.autocrlf "$git_eol"
            printf "%b\n" "${GREEN}Line ending preference set to: ${git_eol}${RC}"
            ;;
        *)
            printf "%b\n" "${YELLOW}Invalid option. Skipping line ending configuration.${RC}"
            ;;
    esac
    
    # Prompt for pull rebase behavior
    printf "%b\n" "${CYAN}=== Git Pull Configuration ===${RC}"
    printf "%b" "${CYAN}Use rebase when pulling (instead of merge)? [y/N]: ${RC}"
    read -r use_rebase_response
    case "$use_rebase_response" in
        [Yy]*)
            git config --global pull.rebase true
            printf "%b\n" "${GREEN}Pull rebase enabled.${RC}"
            ;;
        *)
            git config --global pull.rebase false
            printf "%b\n" "${GREEN}Pull rebase disabled (using merge).${RC}"
            ;;
    esac
    
    # Additional useful configurations
    printf "%b\n" "${CYAN}=== Additional Git Configuration ===${RC}"
    
    # Enable color output
    git config --global color.ui auto
    printf "%b\n" "${GREEN}Color output enabled.${RC}"
    
    # Set default push behavior
    git config --global push.default simple
    printf "%b\n" "${GREEN}Push default set to 'simple'.${RC}"
    
    # Enable credential helper cache (optional; skip when using gh)
    if [ "$USE_GH" = true ]; then
        printf "%b\n" "${CYAN}Credential helper already configured via GitHub CLI.${RC}"
    else
        printf "%b" "${CYAN}Enable credential helper cache (stores credentials for 15 minutes)? [Y/n]: ${RC}"
        read -r use_credential_cache
        case "$use_credential_cache" in
            [Nn]*)
                printf "%b\n" "${YELLOW}Credential helper cache skipped.${RC}"
                ;;
            *)
                git config --global credential.helper cache
                printf "%b\n" "${GREEN}Credential helper cache enabled.${RC}"
                ;;
        esac
    fi
    
    # GPG signing (optional)
    printf "%b" "${CYAN}Do you want to configure GPG signing for commits? [y/N]: ${RC}"
    read -r use_gpg
    case "$use_gpg" in
        [Yy]*)
            printf "%b" "${CYAN}Enter your GPG key ID (leave empty to skip): ${RC}"
            read -r gpg_key
            if [ -n "$gpg_key" ]; then
                git config --global user.signingkey "$gpg_key"
                git config --global commit.gpgsign true
                printf "%b\n" "${GREEN}GPG signing configured with key: ${gpg_key}${RC}"
            fi
            ;;
        *)
            printf "%b\n" "${YELLOW}GPG signing skipped.${RC}"
            ;;
    esac
}

displayGitConfig() {
    printf "%b\n" "${CYAN}=== Current Git Configuration ===${RC}"
    git config --global --list | grep -E "(user\.|core\.|init\.|pull\.|push\.|credential\.|commit\.)" || true
}

USE_GH=false

checkEnv
checkEscalationTool
checkGitInstalled
maybeSetupWithGh
configureGit
displayGitConfig
