#!/bin/sh -e

. ../common-script.sh

installNode() {
    printf "%b\n" "${YELLOW}Installing Node.js via NVM (latest)...${RC}"

    # Ensure curl, bash, and git are available
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm curl bash git
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add curl bash git
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy curl bash git
            ;;
        *)
            "$ESCALATION_TOOL" "$PACKAGER" install -y curl bash git
            ;;
    esac

    # Install NVM without hardcoded version: use latest release tag; fallback to master
    NVM_DIR="$HOME/.nvm"
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        rm -rf "$NVM_DIR"
        latest_tag=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -o '"tag_name"[: ][^,]*' | head -n1 | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\(v[^"[:space:]]*\)".*/\1/')
        [ -z "$latest_tag" ] && latest_tag="master"
        git clone --depth 1 --branch "$latest_tag" https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    fi

    # Load NVM into this shell
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

    # Ensure nvm function is available before proceeding
    if ! command -v nvm >/dev/null 2>&1; then
        printf "%b\n" "${RED}nvm not available after installation. Check NVM_DIR and your shell init files.${RC}"
        exit 1
    fi

    # Install latest Node (current) and set as default
    nvm install node
    nvm use node
    nvm alias default node

    # Enable Corepack (yarn/pnpm)
    if command_exists corepack; then
        corepack enable || true
        corepack prepare yarn@stable --activate || true
        corepack prepare pnpm@latest --activate || true
    fi

    # Ensure NVM loads in future shells
    SHELL_RC="${HOME}/.bashrc"
    [ "$(basename "$SHELL")" = "zsh" ] && SHELL_RC="${HOME}/.zshrc"
    if ! grep -q "NVM_DIR=\"\$HOME/.nvm\"" "$SHELL_RC" 2>/dev/null; then
        {
            printf "%s\n" ''
            cat <<'RCAPPEND'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
RCAPPEND
        } >> "$SHELL_RC"
    fi

    printf "%b\n" "${GREEN}Node.js (current) installed via NVM. Restart your shell to use 'node' and 'npm'.${RC}"
}

checkEnv
installNode


