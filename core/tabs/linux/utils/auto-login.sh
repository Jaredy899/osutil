#!/bin/sh -e 

. ../common-script.sh   

# Helper function to map desktop environment names to session files
map_desktop_to_session() {
    case "$1" in
        *gnome*) echo "gnome.desktop" ;;
        *plasma*) echo "plasma.desktop" ;;
        *xfce*) echo "xfce.desktop" ;;
        *lxde*) echo "LXDE.desktop" ;;
        *lxqt*) echo "lxqt.desktop" ;;
        *cinnamon*) echo "cinnamon.desktop" ;;
        *mate*) echo "mate.desktop" ;;
        *openbox*) echo "openbox.desktop" ;;
        *i3*) echo "i3.desktop" ;;
        *) echo "" ;;
    esac
}

# Helper function to check if process is running
process_running() {
    pgrep -f "$1" > /dev/null 2>&1
}

# Function to detect current desktop session
detect_session() {
    printf "%b\n" "Detecting current desktop session..."

    # Method 1: Check environment variables
    for env_var in "$XDG_CURRENT_DESKTOP" "$DESKTOP_SESSION" "$GDMSESSION"; do
        if [ -n "$env_var" ]; then
            session=$(map_desktop_to_session "$env_var")
            [ -n "$session" ] && break
        fi
    done

    # Method 2: Check running processes
    if [ -z "$session" ]; then
        for process in "gnome-shell" "plasmashell" "xfce4-session" "lxsession" "lxqt-session" \
                      "cinnamon-session" "mate-session" "openbox-session" "i3"; do
            if process_running "$process"; then
                session=$(map_desktop_to_session "$process")
                [ -n "$session" ] && break
            fi
        done
    fi

    if [ -n "$session" ]; then
        printf "%b\n" "Detected session: $session"
    else
        printf "%b\n" "Could not detect desktop session automatically."
        printf "%b" "Enter session name (e.g., gnome.desktop, plasma.desktop): "
        read -r session
    fi
}

# Helper function to check if service is active
service_active() {
    systemctl is-active --quiet "$1" 2>/dev/null
}

# Helper function to check if file exists
file_exists() {
    [ -f "$1" ]
}

# Function to detect current display manager
detect_display_manager() {
    printf "%b\n" "Detecting current display manager..."

    # Method 1: Check running processes
    for dm_name in "lightdm" "gdm" "sddm" "lxdm"; do
        if process_running "$dm_name"; then
            dm="$dm_name"
            break
        fi
    done

    # Method 2: Check active services
    if [ -z "$dm" ]; then
        for dm_name in "lightdm" "gdm" "sddm" "lxdm"; do
            if service_active "$dm_name"; then
                dm="$dm_name"
                break
            fi
        done
    fi

    # Method 3: Check configuration files
    if [ -z "$dm" ]; then
        if file_exists "/etc/lightdm/lightdm.conf"; then dm="lightdm"
        elif file_exists "/etc/gdm/custom.conf"; then dm="gdm"
        elif file_exists "/etc/sddm.conf"; then dm="sddm"
        elif file_exists "/etc/lxdm/lxdm.conf"; then dm="lxdm"
        fi
    fi

    # Method 4: Check XDG_SESSION environment variable
    if [ -z "$dm" ] && [ -n "$XDG_SESSION_DESKTOP" ]; then
        for dm_name in "lightdm" "gdm" "sddm" "lxdm"; do
            case "$XDG_SESSION_DESKTOP" in
                *"$dm_name"*) dm="$dm_name" && break ;;
            esac
        done
    fi

    if [ -n "$dm" ]; then
        printf "%b\n" "Detected display manager: $dm"
    else
        printf "%b\n" "Could not detect display manager automatically."
        printf "%b\n" "Available display managers:"
        printf "%b\n" "1) LightDM"
        printf "%b\n" "2) GDM"
        printf "%b\n" "3) SDDM"
        printf "%b\n" "4) LXDM"
        printf "%b" "Enter your choice (1-4): "
        read -r dm_choice
        case "$dm_choice" in
            1) dm="lightdm" ;;
            2) dm="gdm" ;;
            3) dm="sddm" ;;
            4) dm="lxdm" ;;
            *) printf "%b\n" "Invalid choice. Exiting..." && exit 1 ;;
        esac
    fi
}

# Function to configure LightDM
configure_lightdm() {
    printf "%b\n" "Configuring LightDM for autologin..."
    printf "%b" "Enter username for LightDM autologin: "
    read -r user

    printf "%b\n" '[Seat:*]' | "$ESCALATION_TOOL" tee -a /etc/lightdm/lightdm.conf
    printf "%s\n" "autologin-user=$user" | "$ESCALATION_TOOL" tee -a /etc/lightdm/lightdm.conf
    printf "%b\n" 'autologin-user-timeout=0' | "$ESCALATION_TOOL" tee -a /etc/lightdm/lightdm.conf

    printf "%b\n" "LightDM has been configured for autologin."
}

# Function to remove LightDM autologin
remove_lightdm_autologin() {
    printf "%b\n" "Removing LightDM autologin configuration..."
    "$ESCALATION_TOOL" sed -i'' '/^\[Seat:\*]/d' /etc/lightdm/lightdm.conf
    "$ESCALATION_TOOL" sed -i'' '/^autologin-/d' /etc/lightdm/lightdm.conf
    printf "%b\n" "LightDM autologin configuration has been removed."
}

# Function to configure GDM
configure_gdm() {
    printf "%b\n" "Configuring GDM for autologin..."
    printf "%b" "Enter username for GDM autologin: "
    read -r user

    printf "%b\n" '[daemon]' | "$ESCALATION_TOOL" tee -a /etc/gdm/custom.conf
    printf "%b\n" 'AutomaticLoginEnable = true' | "$ESCALATION_TOOL" tee -a /etc/gdm/custom.conf
    printf "%s\n" "AutomaticLogin = $user" | "$ESCALATION_TOOL" tee -a /etc/gdm/custom.conf

    printf "%b\n" "GDM has been configured for autologin."
}

# Function to remove GDM autologin
remove_gdm_autologin() {
    printf "%b\n" "Removing GDM autologin configuration..."
    "$ESCALATION_TOOL" sed -i'' '/AutomaticLoginEnable/d' /etc/gdm/custom.conf
    "$ESCALATION_TOOL" sed -i'' '/AutomaticLogin/d' /etc/gdm/custom.conf
    printf "%b\n" "GDM autologin configuration has been removed."
}

# Function to configure SDDM
configure_sddm() {
    printf "%b\n" "Configuring SDDM for autologin..."
    printf "%b" "Enter username for SDDM autologin: "
    read -r user
    detect_session  # Auto-detect session

    printf "%b\n" '[Autologin]' | "$ESCALATION_TOOL" tee -a /etc/sddm.conf
    printf "%s\n" "User=$user" | "$ESCALATION_TOOL" tee -a /etc/sddm.conf
    printf "%s\n" "Session=$session" | "$ESCALATION_TOOL" tee -a /etc/sddm.conf

    printf "%b\n" "SDDM has been configured for autologin."
}

# Function to remove SDDM autologin
remove_sddm_autologin() {
    printf "%b\n" "Removing SDDM autologin configuration..."
    "$ESCALATION_TOOL" sed -i'' '/\[Autologin\]/,+2d' /etc/sddm.conf
    printf "%b\n" "SDDM autologin configuration has been removed."
}

# Function to configure LXDM
configure_lxdm() {
    printf "%b\n" "Configuring LXDM for autologin..."
    printf "%b" "Enter username for LXDM autologin: "
    read -r user
    detect_session  # Auto-detect session

    "$ESCALATION_TOOL" sed -i'' "s/^#.*autologin=.*$/autologin=${user}/" /etc/lxdm/lxdm.conf
    "$ESCALATION_TOOL" sed -i'' "s|^#.*session=.*$|session=/usr/bin/${session}|; s|^session=.*$|session=/usr/bin/${session}|" /etc/lxdm/lxdm.conf

    printf "%b\n" "LXDM has been configured for autologin."
}

# Function to remove LXDM autologin
remove_lxdm_autologin() {
    printf "%b\n" "Removing LXDM autologin configuration..."
    "$ESCALATION_TOOL" sed -i'' "s/^autologin=.*$/#autologin=/" /etc/lxdm/lxdm.conf
    "$ESCALATION_TOOL" sed -i'' "s/^session=.*$/#session=/" /etc/lxdm/lxdm.conf
    printf "%b\n" "LXDM autologin configuration has been removed."
}

# Function to configure or remove autologin based on user choice
configure_or_remove_autologin() {
    printf "%b\n" "Do you want to add or remove autologin?"
    printf "%b\n" "1) Add autologin"
    printf "%b\n" "2) Remove autologin"
    printf "%b" "Enter your choice (1-2): "
    read -r action_choice

    case "$action_choice" in
        1)
            detect_display_manager
            case "$dm" in
                lightdm) configure_lightdm ;;
                gdm) configure_gdm ;;
                sddm) configure_sddm ;;
                lxdm) configure_lxdm ;;
                *) printf "%b\n" "Unsupported display manager: $dm" && exit 1 ;;
            esac
            ;;
        2)
            detect_display_manager
            case "$dm" in
                lightdm) remove_lightdm_autologin ;;
                gdm) remove_gdm_autologin ;;
                sddm) remove_sddm_autologin ;;
                lxdm) remove_lxdm_autologin ;;
                *) printf "%b\n" "Unsupported display manager: $dm" && exit 1 ;;
            esac
            ;;
        *)
            printf "%b\n" "Invalid choice. Exiting..."
            exit 1
            ;;
    esac

    printf "%b\n" "Action completed. Exiting..."
    exit 0
}

checkEnv
checkEscalationTool
configure_or_remove_autologin
