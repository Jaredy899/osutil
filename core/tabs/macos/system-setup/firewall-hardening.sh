#!/bin/sh -e

. ../common-script.sh

SOCKETFW="/usr/libexec/ApplicationFirewall/socketfilterfw"

ensure_socketfw() {
    if [ ! -x "$SOCKETFW" ]; then
        printf "%b\n" "${RED}socketfilterfw not found at $SOCKETFW${RC}"
        exit 1
    fi
}

enable_firewall() {
    printf "%b\n" "${CYAN}Enabling Application Firewall...${RC}"
    "$ESCALATION_TOOL" "$SOCKETFW" --setglobalstate on >/dev/null 2>&1 || true
}

enable_stealth() {
    printf "%b\n" "${CYAN}Enabling Stealth Mode...${RC}"
    "$ESCALATION_TOOL" "$SOCKETFW" --setstealthmode on >/dev/null 2>&1 || true
}

maybe_block_all() {
    printf "%b" "${YELLOW}Enable Block All Incoming (most restrictive)? [y/N]: ${RC}"
    read -r reply || reply=""
    case "$reply" in
        y|Y)
            printf "%b\n" "${CYAN}Enabling Block All Incoming...${RC}"
            "$ESCALATION_TOOL" "$SOCKETFW" --setblockall on >/dev/null 2>&1 || true
            ;;
        *)
            printf "%b\n" "${YELLOW}Keeping Block All Incoming disabled.${RC}"
            ;;
    esac
}

show_status() {
    printf "%b\n" "${GREEN}Firewall status:${RC}"
    "$ESCALATION_TOOL" "$SOCKETFW" --getglobalstate || true
    "$ESCALATION_TOOL" "$SOCKETFW" --getstealthmode || true
    if "$SOCKETFW" --help 2>&1 | grep -q -- "getblockall"; then
        "$ESCALATION_TOOL" "$SOCKETFW" --getblockall || true
    fi
}

checkEnv
ensure_socketfw
enable_firewall
enable_stealth
maybe_block_all
show_status


