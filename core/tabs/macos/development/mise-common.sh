#!/bin/sh -e
# Shared mise helpers for macOS Development scripts.

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Jaredy899/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

ensureMiseInPath() {
    if command_exists mise; then
        return 0
    fi

    for candidate in \
        "$HOME/.local/bin/mise" \
        "$HOME/.cargo/bin/mise" \
        /opt/homebrew/bin/mise \
        /usr/local/bin/mise; do
        if [ -x "$candidate" ]; then
            case ":$PATH:" in
                *":$(dirname "$candidate"):"*) ;;
                *) export PATH="$(dirname "$candidate"):$PATH" ;;
            esac
            break
        fi
    done

    if command_exists mise; then
        eval "$(mise activate zsh)" 2>/dev/null || eval "$(mise activate bash)" 2>/dev/null || true
    fi
}

ensureMise() {
    ensureMiseInPath
    if command_exists mise; then
        return 0
    fi

    # Prefer Homebrew when available
    if command_exists brew; then
        printf "%b\n" "${YELLOW}Installing mise via Homebrew...${RC}"
        brew install mise || true
        ensureMiseInPath
    fi

    if command_exists mise; then
        printf "%b\n" "${GREEN}mise installed successfully${RC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing mise via official installer...${RC}"
    if ! curl -fsSL https://mise.run | sh; then
        printf "%b\n" "${RED}Failed to install mise${RC}"
        return 1
    fi

    ensureMiseInPath
    if ! command_exists mise; then
        printf "%b\n" "${RED}mise installed but not found on PATH. Add ~/.local/bin to PATH and retry.${RC}"
        return 1
    fi

    printf "%b\n" "${GREEN}mise installed successfully${RC}"
}

ensureDotfiles() {
    if [ -d "$DOTFILES_DIR/.git" ]; then
        (cd "$DOTFILES_DIR" && git pull --ff-only) >/dev/null 2>&1 || true
        return 0
    fi
    if [ -d "$DOTFILES_DIR" ]; then
        return 0
    fi
    if ! command_exists git; then
        return 0
    fi
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || true
}

symlinkMiseConfig() {
    ensureDotfiles
    mkdir -p "$HOME/.config/mise"

    if [ ! -f "$DOTFILES_DIR/config/mise/config.toml" ]; then
        printf "%b\n" "${YELLOW}mise config not found in dotfiles, skipping symlink${RC}"
        return 0
    fi

    if [ -e "$HOME/.config/mise/config.toml" ] && [ ! -L "$HOME/.config/mise/config.toml" ] &&
        [ ! -e "$HOME/.config/mise/config.toml.bak" ]; then
        mv "$HOME/.config/mise/config.toml" "$HOME/.config/mise/config.toml.bak"
    fi

    rm -f "$HOME/.config/mise/config.toml"
    ln -sf "$DOTFILES_DIR/config/mise/config.toml" "$HOME/.config/mise/config.toml"
    printf "%b\n" "${GREEN}Symlinked mise config from dotfiles${RC}"
}
