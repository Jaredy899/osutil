#!/bin/sh -e

. ../common-script.sh

installRust() {
    if command_exists rustup; then
        printf "%b\n" "${YELLOW}rustup detected. Updating to latest stable...${RC}"
        rustup default stable || true
        rustup update stable
        rustup component add rustfmt clippy || true
        printf "%b\n" "${GREEN}Rust toolchain is up-to-date (stable).${RC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing rustup and setting stable toolchain...${RC}"
    case "$PACKAGER" in
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y curl rustup man-pages man-db man || true
            rustup-init -y
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add build-base rustup curl || true
            rustup-init -y
            ;;
        *)
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            ;;
    esac

    # shellcheck disable=SC1091
    [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

    rustup default stable
    rustup component add rustfmt clippy || true

    printf "%b\n" "${GREEN}Rust (stable) installed. Restart your shell or source \"$HOME/.cargo/env\" to update PATH.${RC}"
}

checkEnv
installRust


