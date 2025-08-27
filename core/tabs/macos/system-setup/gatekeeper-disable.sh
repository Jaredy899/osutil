#!/bin/sh -e

. ../common-script.sh

show_status() {
    if command -v spctl >/dev/null 2>&1; then
        status=$(spctl --status 2>/dev/null || true)
        case "$status" in
            *enabled*)  printf "%b\n" "${GREEN}Gatekeeper: ENABLED${RC}" ;;
            *disabled*) printf "%b\n" "${RED}Gatekeeper: DISABLED${RC}" ;;
            *)          printf "%b\n" "${YELLOW}Gatekeeper: Unknown status ($status)${RC}" ;;
        esac
    else
        printf "%b\n" "${RED}spctl not found.${RC}"
        exit 1
    fi
}

ensure_disabled() {
	printf "%b\n" "${CYAN}Ensuring Gatekeeper is disabled...${RC}"
	"$ESCALATION_TOOL" spctl --master-disable || true
}

maybe_purge_quarantine() {
    printf "%b" "${YELLOW}Remove quarantine attributes in ~/Downloads and ~/Desktop? [y/N]: ${RC}"
    read -r confirm || confirm=""
    case "$confirm" in
        y|Y)
            printf "%b\n" "${CYAN}Purging quarantine attributes...${RC}"
            xattr -dr com.apple.quarantine "$HOME/Downloads" "$HOME/Desktop" 2>/dev/null || true
            ;;
        *)
            printf "%b\n" "${YELLOW}Skipping quarantine purge.${RC}"
            ;;
    esac
}

checkEnv
printf "%b\n" "${CYAN}Gatekeeper status before:${RC}"
show_status
ensure_disabled
printf "%b\n" "${CYAN}Gatekeeper status after:${RC}"
show_status
maybe_purge_quarantine


