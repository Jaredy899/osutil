#!/bin/sh -e

. ../common-script.sh

apply_recommended() {
    printf "%b\n" "${CYAN}Applying recommended power settings...${RC}"
    # On battery
    "$ESCALATION_TOOL" pmset -b \
        displaysleep 5 \
        disksleep 10 \
        sleep 15 \
        powernap 0 \
        tcpkeepalive 0 \
        standby 1 \
        autopoweroff 1 \
        hibernatemode 3 || true

    # On charger
    "$ESCALATION_TOOL" pmset -c \
        displaysleep 10 \
        disksleep 0 \
        sleep 30 \
        powernap 0 \
        tcpkeepalive 1 \
        standby 1 \
        autopoweroff 1 \
        hibernatemode 0 || true

    printf "%b\n" "${GREEN}Power settings applied.${RC}"
}

restore_defaults() {
    printf "%b\n" "${CYAN}Restoring pmset defaults...${RC}"
    "$ESCALATION_TOOL" pmset -a restoredefaults || true
    printf "%b\n" "${GREEN}pmset defaults restored.${RC}"
}

show_current() {
    printf "%b\n" "${CYAN}Current custom settings:${RC}"
    pmset -g custom || true
}

checkEnv
printf "%b\n" "${CYAN}Power tuning options:${RC}"
printf "%b\n" "1) Apply recommended settings"
printf "%b\n" "2) Restore defaults"
printf "%b\n" "3) Show current settings"
printf "%b" "${YELLOW}Choose an option [1-3]: ${RC}"
read -r choice || choice=3
case "$choice" in
    1) apply_recommended ;;
    2) restore_defaults ;;
    3|*) show_current ;;
esac


