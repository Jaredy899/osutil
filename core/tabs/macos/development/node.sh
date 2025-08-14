#!/bin/sh -e

. ../common-script.sh

installNode() {
    printf "%b\n" "${YELLOW}Installing Node.js via NVM (latest)...${RC}"

    # Ensure dependencies for nvm install (idempotent)
    if command -v brew >/dev/null 2>&1; then
        brew install curl
        brew install git
        brew install bash
    fi

    NVM_DIR="$HOME/.nvm"
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        rm -rf "$NVM_DIR"
        latest_tag=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -o '"tag_name"[: ][^,]*' | head -n1 | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\(v[^"[:space:]]*\)".*/\1/')
        [ -z "$latest_tag" ] && latest_tag="master"
        git clone --depth 1 --branch "$latest_tag" https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    fi

    # shellcheck disable=SC1090
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

    if ! command -v nvm >/dev/null 2>&1; then
        printf "%b\n" "${RED}nvm not available after installation.${RC}"
        exit 1
    fi

    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'

    if command -v corepack >/dev/null 2>&1; then
        if ! corepack enable; then
            printf "%b\n" "${YELLOW}Corepack enable failed, continuing...${RC}"
        fi
        if ! corepack prepare yarn@stable --activate; then
            printf "%b\n" "${YELLOW}Corepack yarn prepare failed, continuing...${RC}"
        fi
        if ! corepack prepare pnpm@latest --activate; then
            printf "%b\n" "${YELLOW}Corepack pnpm prepare failed, continuing...${RC}"
        fi
    fi

    SHELL_RC="${HOME}/.bashrc"
    [ "$(basename "$SHELL")" = "zsh" ] && SHELL_RC="${HOME}/.zshrc"
    if ! grep -q "NVM_DIR=\"\$HOME/.nvm\"" "$SHELL_RC" 2>/dev/null; then
        {
            printf "%s\n" ''
            cat <<'RCAPPEND'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
RCAPPEND
        } >> "$SHELL_RC"
    fi

    printf "%b\n" "${GREEN}Node.js (LTS) installed via NVM.${RC}"
}

checkEnv
installNode


