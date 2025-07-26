#!/bin/sh -e

checkInitManager() {
    for manager in $1; do
        if [ -x "/usr/sbin/$manager" ] || [ -x "/sbin/$manager" ] || command_exists "$manager"; then
            INIT_MANAGER="$manager"
            printf "%b\n" "${CYAN}Using ${manager} to interact with init system${RC}"
            break
        fi
    done

    if [ -z "$INIT_MANAGER" ]; then
        printf "%b\n" "${RED}Can't find a supported init system${RC}"
        exit 1
    fi
}

startService() {
    case "$INIT_MANAGER" in
        systemctl | sv)
            "$ESCALATION_TOOL" "$INIT_MANAGER" start "$1"
            ;;
        rc-service)
            "$ESCALATION_TOOL" "$INIT_MANAGER" "$1" start
            ;;
        service)
            if [ -d "/etc/rc.d" ]; then
                "$ESCALATION_TOOL" "$INIT_MANAGER" start "$1"
            else
                "$ESCALATION_TOOL" "$INIT_MANAGER" "$1" start
            fi
            ;;
    esac
}

stopService() {
    case "$INIT_MANAGER" in
        systemctl | sv)
            "$ESCALATION_TOOL" "$INIT_MANAGER" stop "$1"
            ;;
        rc-service)
            "$ESCALATION_TOOL" "$INIT_MANAGER" "$1" stop
            ;;
        service)
            if [ -d "/etc/rc.d" ]; then
                "$ESCALATION_TOOL" "$INIT_MANAGER" stop "$1"
            else
                "$ESCALATION_TOOL" "$INIT_MANAGER" "$1" stop
            fi
            ;;
    esac
}

enableService() {
    case "$INIT_MANAGER" in
        systemctl)
            "$ESCALATION_TOOL" "$INIT_MANAGER" enable "$1"
            ;;
        rc-service)
            "$ESCALATION_TOOL" rc-update add "$1"
            ;;
        sv)
            if [ -d "/etc/service" ]; then
                "$ESCALATION_TOOL" ln -sf "/etc/sv/$1" "/etc/service/"
            else
                "$ESCALATION_TOOL" ln -sf "/etc/sv/$1" "/var/service/"
            fi
            ;;
        service)
            if [ -d "/etc/rc.d" ]; then
                "$ESCALATION_TOOL" chmod +x "/etc/rc.d/rc.$1"
            else
                "$ESCALATION_TOOL" update-rc.d "$1" defaults
            fi
            ;;
    esac
}

disableService() {
    case "$INIT_MANAGER" in
        systemctl)
            "$ESCALATION_TOOL" "$INIT_MANAGER" disable "$1"
            ;;
        rc-service)
            "$ESCALATION_TOOL" rc-update del "$1"
            ;;
        sv)
            "$ESCALATION_TOOL" rm -f "/etc/service/$1" "/var/service/$1"
            ;;
        service)
            if [ -d "/etc/rc.d" ]; then
                "$ESCALATION_TOOL" chmod -x "/etc/rc.d/rc.$1"
            else
                "$ESCALATION_TOOL" update-rc.d -f "$1" remove
            fi
            ;;
    esac
}

startAndEnableService() {
    case "$INIT_MANAGER" in
        systemctl)
            "$ESCALATION_TOOL" "$INIT_MANAGER" enable --now "$1"
            ;;
        rc-service | service)
            enableService "$1"
            startService "$1"
            ;;
        sv)
            enableService "$1"
            ;;
    esac
}

isServiceActive() {
    case "$INIT_MANAGER" in
        systemctl)
            "$ESCALATION_TOOL" "$INIT_MANAGER" is-active --quiet "$1"
            ;;
        rc-service)
            "$ESCALATION_TOOL" "$INIT_MANAGER" "$1" status --quiet
            ;;
        sv)
            "$ESCALATION_TOOL" "$INIT_MANAGER" status "$1" >/dev/null 2>&1
            ;;
        service)
            if [ "$INIT_MANAGER" = "service" ]; then
                "$ESCALATION_TOOL" "$INIT_MANAGER" list 2>/dev/null \
                    | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' \
                    | grep -q -E "^$1.*\[on\]"
            else
                "$ESCALATION_TOOL" "$INIT_MANAGER" "$1" status | grep -q 'running'
            fi
            ;;
    esac
}

checkInitManager 'systemctl rc-service sv service'
