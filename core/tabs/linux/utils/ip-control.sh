#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Helpers
prefix_to_netmask() {
    prefix_len="$1"
    case "$prefix_len" in
        8)  echo "255.0.0.0" ;;
        9)  echo "255.128.0.0" ;;
        10) echo "255.192.0.0" ;;
        11) echo "255.224.0.0" ;;
        12) echo "255.240.0.0" ;;
        13) echo "255.248.0.0" ;;
        14) echo "255.252.0.0" ;;
        15) echo "255.254.0.0" ;;
        16) echo "255.255.0.0" ;;
        17) echo "255.255.128.0" ;;
        18) echo "255.255.192.0" ;;
        19) echo "255.255.224.0" ;;
        20) echo "255.255.240.0" ;;
        21) echo "255.255.248.0" ;;
        22) echo "255.255.252.0" ;;
        23) echo "255.255.254.0" ;;
        24) echo "255.255.255.0" ;;
        25) echo "255.255.255.128" ;;
        26) echo "255.255.255.192" ;;
        27) echo "255.255.255.224" ;;
        28) echo "255.255.255.240" ;;
        29) echo "255.255.255.248" ;;
        30) echo "255.255.255.252" ;;
        31) echo "255.255.255.254" ;;
        32) echo "255.255.255.255" ;;
        *)  echo "" ;;
    esac
}

list_interfaces_raw() {
    if command_exists nmcli; then
        nmcli -t -f DEVICE,TYPE,STATE device status \
            | awk -F: '($2=="ethernet"||$2=="wifi"){print $1}'
        return
    fi
    # Prefer likely physical/wireless names; strip @ suffix
    ip -o link show \
        | awk -F': ' '($2!="lo"){print $2}' \
        | sed 's/@.*$//' \
        | grep -E '^(e(th|n|np)|wl|ww)' || true
}

pretty_print_interfaces() {
    if command_exists nmcli; then
        nmcli -t -f DEVICE,TYPE,STATE device status \
            | awk -F: '($2=="ethernet"||$2=="wifi"){printf "%s (%s - %s)\n", $1, $2, $3}'
        return
    fi
    # Fallback: show raw device names
    list_interfaces_raw
}

select_interface() {
    # Build list
    interfaces=$(list_interfaces_raw)
    # If empty (regex filtered out everything), fallback to all non-lo
    if [ -z "$interfaces" ]; then
        interfaces=$(ip -o link show | awk -F': ' '($2!="lo"){print $2}' | sed 's/@.*$//')
    fi

    # Enumerate for display
    printf "%b\n" "${YELLOW}Available interfaces:${RC}"
    i=1
    printf "%s" "$interfaces" | while IFS= read -r iface; do
        [ -z "$iface" ] && continue
        # Determine a simple type label when nmcli is absent
        label=""
        if command_exists nmcli; then
            label=$(nmcli -t -f DEVICE,TYPE,STATE device status | awk -F: -v d="$iface" '($1==d){printf " (%s - %s)", $2, $3}')
        fi
        printf "%d. %s%s\n" "$i" "$iface" "$label"
        i=$((i+1))
    done

    printf "%b" "${CYAN}Enter number or interface name (e.g., 1 or eth0): ${RC}"
    read -r INPUT_SEL
    if [ -z "$INPUT_SEL" ]; then
        printf "%b\n" "${RED}No interface selected.${RC}"
        exit 1
    fi
    if printf "%s" "$INPUT_SEL" | grep -qE '^[0-9]+$'; then
        # Numeric selection
        idx="$INPUT_SEL"
        SELECTED_INTERFACE=$(printf "%s" "$interfaces" | sed -n "${idx}p")
    else
        # Name selection
        SELECTED_INTERFACE="$INPUT_SEL"
    fi
    # Normalize: strip any @suffix if provided
    SELECTED_INTERFACE=$(printf "%s" "$SELECTED_INTERFACE" | sed 's/@.*$//')
    if [ -z "$SELECTED_INTERFACE" ]; then
        printf "%b\n" "${RED}Invalid selection.${RC}"
        exit 1
    fi
}

prompt_static_ipv4() {
    printf "%b" "${CYAN}Enter IPv4 address (e.g., 192.168.1.50): ${RC}"
    read -r STATIC_IP
    printf "%b" "${CYAN}Enter prefix length (e.g., 24 for /24): ${RC}"
    read -r STATIC_PREFIX
    printf "%b" "${CYAN}Enter gateway IPv4 (optional): ${RC}"
    read -r STATIC_GW
    printf "%b" "${CYAN}Enter DNS servers (comma or space separated, optional): ${RC}"
    read -r STATIC_DNS_INPUT
    # Normalize DNS list to comma-separated for nmcli and YAML
    STATIC_DNS=$(printf "%s" "$STATIC_DNS_INPUT" | tr ' ' ',' | sed 's/,,*/,/g; s/^,//; s/,$//')
    [ -z "$STATIC_IP" ] || [ -z "$STATIC_PREFIX" ] && {
        printf "%b\n" "${RED}IP and prefix are required.${RC}"
        exit 1
    }
}

# Backends
configure_with_nmcli_static() {
    iface="$1"; ip_addr="$2"; prefix="$3"; gateway="$4"; dns_list="$5"
    con_name=$(nmcli -t -f NAME,DEVICE con show | awk -F: -v d="$iface" '$2==d{print $1; exit}')
    if [ -z "$con_name" ]; then
        con_name="$iface"
        nmcli con add type ethernet ifname "$iface" con-name "$con_name" >/dev/null 2>&1 || true
    fi
    nmcli con mod "$con_name" ipv4.method manual ipv4.addresses "$ip_addr/$prefix"
    [ -n "$gateway" ] && nmcli con mod "$con_name" ipv4.gateway "$gateway"
    if [ -n "$dns_list" ]; then
        nmcli con mod "$con_name" ipv4.dns "$dns_list"
    else
        nmcli con mod "$con_name" ipv4.ignore-auto-dns yes
    fi
    nmcli con mod "$con_name" connection.autoconnect yes
    nmcli con up "$con_name"
}

configure_with_nmcli_dhcp() {
    iface="$1"
    con_name=$(nmcli -t -f NAME,DEVICE con show | awk -F: -v d="$iface" '$2==d{print $1; exit}')
    if [ -z "$con_name" ]; then
        con_name="$iface"
        nmcli con add type ethernet ifname "$iface" con-name "$con_name" >/dev/null 2>&1 || true
    fi
    nmcli con mod "$con_name" ipv4.method auto ipv4.addresses "" ipv4.gateway "" ipv4.dns ""
    nmcli con mod "$con_name" ipv4.ignore-auto-dns no
    nmcli con up "$con_name"
}

configure_with_netplan_static() {
    iface="$1"; ip_addr="$2"; prefix="$3"; gateway="$4"; dns_list="$5"
    netplan_file="/etc/netplan/99-osutil-${iface}.yaml"
    {
        printf "# Generated by osutil ip-control\n"
        printf "network:\n"
        printf "  version: 2\n"
        printf "  ethernets:\n"
        printf "    %s:\n" "$iface"
        printf "      addresses: ['%s/%s']\n" "$ip_addr" "$prefix"
        [ -n "$gateway" ] && printf "      gateway4: %s\n" "$gateway"
        if [ -n "$dns_list" ]; then
            # Convert comma list to YAML array
            dns_yaml=$(printf "%s" "$dns_list" | awk -F, '{for(i=1;i<=NF;i++){gsub(/^ +| +$/,"",$i); if($i!="") printf("%s%s",(i==1?"":" "),$i)}}')
            printf "      nameservers:\n"
            printf "        addresses: [%s]\n" "$dns_yaml"
        fi
    } | "$ESCALATION_TOOL" tee "$netplan_file" >/dev/null
    if command_exists netplan; then
        "$ESCALATION_TOOL" netplan apply
    fi
}

configure_with_netplan_dhcp() {
    iface="$1"
    netplan_file="/etc/netplan/99-osutil-${iface}.yaml"
    {
        printf "# Generated by osutil ip-control\n"
        printf "network:\n"
        printf "  version: 2\n"
        printf "  ethernets:\n"
        printf "    %s:\n" "$iface"
        printf "      dhcp4: true\n"
    } | "$ESCALATION_TOOL" tee "$netplan_file" >/dev/null
    if command_exists netplan; then
        "$ESCALATION_TOOL" netplan apply
    fi
}

configure_with_networkd_static() {
    iface="$1"; ip_addr="$2"; prefix="$3"; gateway="$4"; dns_list="$5"
    file_path="/etc/systemd/network/10-${iface}.network"
    {
        printf "[Match]\nName=%s\n\n" "$iface"
        printf "[Network]\nAddress=%s/%s\n" "$ip_addr" "$prefix"
        [ -n "$gateway" ] && printf "Gateway=%s\n" "$gateway"
        if [ -n "$dns_list" ]; then
            printf "%s" "$dns_list" | tr ',' ' ' | awk '{for(i=1;i<=NF;i++) printf("DNS=%s\n", $i)}'
        fi
    } | "$ESCALATION_TOOL" tee "$file_path" >/dev/null
    "$ESCALATION_TOOL" systemctl enable --now systemd-networkd >/dev/null 2>&1 || true
    "$ESCALATION_TOOL" systemctl restart systemd-networkd
}

configure_with_networkd_dhcp() {
    iface="$1"
    file_path="/etc/systemd/network/10-${iface}.network"
    {
        printf "[Match]\nName=%s\n\n" "$iface"
        printf "[Network]\nDHCP=yes\n"
    } | "$ESCALATION_TOOL" tee "$file_path" >/dev/null
    "$ESCALATION_TOOL" systemctl enable --now systemd-networkd >/dev/null 2>&1 || true
    "$ESCALATION_TOOL" systemctl restart systemd-networkd
}

configure_with_ifupdown_static() {
    iface="$1"; ip_addr="$2"; prefix="$3"; gateway="$4"; dns_list="$5"
    netmask=$(prefix_to_netmask "$prefix")
    [ -z "$netmask" ] && { printf "%b\n" "${RED}Invalid prefix length for ifupdown.${RC}"; exit 1; }
    interfaces_file="/etc/network/interfaces"
    tmp_file=$(mktemp)
    # Remove existing stanza for iface
    awk -v IF="$iface" '
        BEGIN{skip=0}
        /^auto[ \t]+/ {print}
        /^allow-hotplug[ \t]+/ {print}
        /^iface[ \t]+/ {
            if($2==IF){skip=1; next}
        }
        skip==1 {
            if(/^iface[ \t]+/){skip=0; print}
            next
        }
        {print}
    ' "$interfaces_file" > "$tmp_file" 2>/dev/null || true
    "$ESCALATION_TOOL" cp "$tmp_file" "$interfaces_file" 2>/dev/null || true
    rm -f "$tmp_file"
    {
        printf "\nauto %s\n" "$iface"
        printf "iface %s inet static\n" "$iface"
        printf "    address %s\n" "$ip_addr"
        printf "    netmask %s\n" "$netmask"
        [ -n "$gateway" ] && printf "    gateway %s\n" "$gateway"
        if [ -n "$dns_list" ]; then
            printf "    dns-nameservers %s\n" "$(printf "%s" "$dns_list" | tr ',' ' ')"
        fi
    } | "$ESCALATION_TOOL" tee -a "$interfaces_file" >/dev/null
    case "$INIT_MANAGER" in
        systemctl) "$ESCALATION_TOOL" systemctl restart networking || true ;;
        rc-service) "$ESCALATION_TOOL" rc-service networking restart || true ;;
        service) "$ESCALATION_TOOL" service networking restart || true ;;
    esac
}

configure_with_ifupdown_dhcp() {
    iface="$1"
    interfaces_file="/etc/network/interfaces"
    tmp_file=$(mktemp)
    awk -v IF="$iface" '
        BEGIN{skip=0}
        /^auto[ \t]+/ {print}
        /^allow-hotplug[ \t]+/ {print}
        /^iface[ \t]+/ {
            if($2==IF){skip=1; next}
        }
        skip==1 {
            if(/^iface[ \t]+/){skip=0; print}
            next
        }
        {print}
    ' "$interfaces_file" > "$tmp_file" 2>/dev/null || true
    "$ESCALATION_TOOL" cp "$tmp_file" "$interfaces_file" 2>/dev/null || true
    rm -f "$tmp_file"
    {
        printf "\nauto %s\n" "$iface"
        printf "iface %s inet dhcp\n" "$iface"
    } | "$ESCALATION_TOOL" tee -a "$interfaces_file" >/dev/null
    case "$INIT_MANAGER" in
        systemctl) "$ESCALATION_TOOL" systemctl restart networking || true ;;
        rc-service) "$ESCALATION_TOOL" rc-service networking restart || true ;;
        service) "$ESCALATION_TOOL" service networking restart || true ;;
    esac
}

configure_with_dhcpcd_static() {
    iface="$1"; ip_addr="$2"; prefix="$3"; gateway="$4"; dns_list="$5"
    conf="/etc/dhcpcd.conf"
    backup="/etc/dhcpcd.conf.bak.osutil"
    "$ESCALATION_TOOL" cp "$conf" "$backup" 2>/dev/null || true
    tmp=$(mktemp)
    awk -v IF="$iface" '
        BEGIN{skip=0}
        /^interface[ \t]+/ {
            if($2==IF){skip=1; next}
        }
        skip==1 {
            if(/^interface[ \t]+/){skip=0; print}
            next
        }
        {print}
    ' "$conf" > "$tmp" 2>/dev/null || true
    "$ESCALATION_TOOL" cp "$tmp" "$conf" 2>/dev/null || true
    rm -f "$tmp"
    {
        printf "\ninterface %s\n" "$iface"
        printf "static ip_address=%s/%s\n" "$ip_addr" "$prefix"
        [ -n "$gateway" ] && printf "static routers=%s\n" "$gateway"
        if [ -n "$dns_list" ]; then
            printf "static domain_name_servers=%s\n" "$(printf "%s" "$dns_list" | tr ',' ' ')"
        fi
    } | "$ESCALATION_TOOL" tee -a "$conf" >/dev/null
    if command_exists systemctl; then "$ESCALATION_TOOL" systemctl restart dhcpcd || true; fi
    if command_exists sv; then "$ESCALATION_TOOL" sv restart dhcpcd || true; fi
}

configure_with_dhcpcd_dhcp() {
    iface="$1"
    conf="/etc/dhcpcd.conf"
    backup="/etc/dhcpcd.conf.bak.osutil"
    "$ESCALATION_TOOL" cp "$conf" "$backup" 2>/dev/null || true
    tmp=$(mktemp)
    awk -v IF="$iface" '
        BEGIN{skip=0}
        /^interface[ \t]+/ {
            if($2==IF){skip=1; next}
        }
        skip==1 {
            if(/^interface[ \t]+/){skip=0; print}
            next
        }
        {print}
    ' "$conf" > "$tmp" 2>/dev/null || true
    "$ESCALATION_TOOL" cp "$tmp" "$conf" 2>/dev/null || true
    rm -f "$tmp"
    if command_exists systemctl; then "$ESCALATION_TOOL" systemctl restart dhcpcd || true; fi
    if command_exists sv; then "$ESCALATION_TOOL" sv restart dhcpcd || true; fi
}

# Orchestration
apply_static_config() {
    select_interface
    prompt_static_ipv4

    if command_exists nmcli; then
        printf "%b\n" "${YELLOW}Applying static IP using NetworkManager (nmcli)...${RC}"
        configure_with_nmcli_static "$SELECTED_INTERFACE" "$STATIC_IP" "$STATIC_PREFIX" "$STATIC_GW" "$STATIC_DNS"
        return
    fi

    if [ -d /etc/netplan ] && command_exists netplan; then
        printf "%b\n" "${YELLOW}Applying static IP using netplan...${RC}"
        configure_with_netplan_static "$SELECTED_INTERFACE" "$STATIC_IP" "$STATIC_PREFIX" "$STATIC_GW" "$STATIC_DNS"
        return
    fi

    if command_exists systemctl && "$ESCALATION_TOOL" systemctl is-active --quiet systemd-networkd; then
        printf "%b\n" "${YELLOW}Applying static IP using systemd-networkd...${RC}"
        configure_with_networkd_static "$SELECTED_INTERFACE" "$STATIC_IP" "$STATIC_PREFIX" "$STATIC_GW" "$STATIC_DNS"
        return
    fi

    if [ -f /etc/network/interfaces ]; then
        printf "%b\n" "${YELLOW}Applying static IP using ifupdown (/etc/network/interfaces)...${RC}"
        configure_with_ifupdown_static "$SELECTED_INTERFACE" "$STATIC_IP" "$STATIC_PREFIX" "$STATIC_GW" "$STATIC_DNS"
        return
    fi

    if command_exists dhcpcd; then
        printf "%b\n" "${YELLOW}Applying static IP using dhcpcd...${RC}"
        configure_with_dhcpcd_static "$SELECTED_INTERFACE" "$STATIC_IP" "$STATIC_PREFIX" "$STATIC_GW" "$STATIC_DNS"
        return
    fi

    printf "%b\n" "${RED}No supported network configuration backend found.${RC}"
    exit 1
}

apply_dhcp_config() {
    select_interface

    if command_exists nmcli; then
        printf "%b\n" "${YELLOW}Enabling DHCP using NetworkManager (nmcli)...${RC}"
        configure_with_nmcli_dhcp "$SELECTED_INTERFACE"
        return
    fi

    if [ -d /etc/netplan ] && command_exists netplan; then
        printf "%b\n" "${YELLOW}Enabling DHCP using netplan...${RC}"
        configure_with_netplan_dhcp "$SELECTED_INTERFACE"
        return
    fi

    if command_exists systemctl && "$ESCALATION_TOOL" systemctl is-active --quiet systemd-networkd; then
        printf "%b\n" "${YELLOW}Enabling DHCP using systemd-networkd...${RC}"
        configure_with_networkd_dhcp "$SELECTED_INTERFACE"
        return
    fi

    if [ -f /etc/network/interfaces ]; then
        printf "%b\n" "${YELLOW}Enabling DHCP using ifupdown (/etc/network/interfaces)...${RC}"
        configure_with_ifupdown_dhcp "$SELECTED_INTERFACE"
        return
    fi

    if command_exists dhcpcd; then
        printf "%b\n" "${YELLOW}Enabling DHCP using dhcpcd...${RC}"
        configure_with_dhcpcd_dhcp "$SELECTED_INTERFACE"
        return
    fi

    printf "%b\n" "${RED}No supported network configuration backend found.${RC}"
    exit 1
}

show_current_ip() {
    select_interface
    printf "%b\n" "${CYAN}Current IPv4 addresses for ${SELECTED_INTERFACE}:${RC}"
    ip -4 addr show dev "$SELECTED_INTERFACE" | sed 's/^\s\+//'
}

main_menu() {
    while true; do
        printf "%b\n" "${YELLOW}IP Address Configuration${RC}"
        printf "%b\n" "1) Set static IPv4"
        printf "%b\n" "2) Set DHCP IPv4"
        printf "%b\n" "3) Show current IPv4 for an interface"
        printf "%b\n" "0) Exit"
        printf "%b" "Choose an option: "
        read -r CHOICE
        case "$CHOICE" in
            1) apply_static_config ;;
            2) apply_dhcp_config ;;
            3) show_current_ip ;;
            0) exit 0 ;;
            *) printf "%b\n" "${RED}Invalid option. Try again.${RC}" ;;
        esac
        printf "%b\n" "Press [Enter] to continue..."; read -r _
    done
}

# Init
checkEnv
checkEscalationTool
main_menu


