#!/bin/sh -e

. ../common-script.sh

show_status() {
    if command -v spctl >/dev/null 2>&1; then
        spctl --status || true
    else
        printf "%b\n" "${RED}spctl not found.${RC}"
        exit 1
    fi
}

ensure_enabled() {
    printf "%b\n" "${CYAN}Ensuring Gatekeeper is enabled...${RC}"
    "$ESCALATION_TOOL" spctl --master-enable || true
}

maybe_purge_quarantine() {
    printf "%b" "${YELLOW}Remove quarantine attributes in ~/Downloads (unquarantine)? [y/N]: ${RC}"
    read -r confirm || confirm=""
    case "$confirm" in
        y|Y)
            printf "%b\n" "${CYAN}Purging quarantine attributes under ~/Downloads...${RC}"
            xattr -dr com.apple.quarantine "$HOME/Downloads" 2>/dev/null || true
            ;;
        *)
            printf "%b\n" "${YELLOW}Skipping quarantine purge.${RC}"
            ;;
    esac
}

checkEnv
printf "%b\n" "${CYAN}Gatekeeper status before:${RC}"
show_status
ensure_enabled
printf "%b\n" "${CYAN}Gatekeeper status after:${RC}"
show_status
maybe_purge_quarantine


