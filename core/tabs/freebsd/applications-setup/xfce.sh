#!/bin/sh -e

. ../common-script.sh

installXFCE() {
    printf "%b\n" "${YELLOW}Installing XFCE desktop environment...${RC}"

    # Install XFCE and related packages
    printf "%b\n" "${CYAN}Installing XFCE desktop environment...${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" install -y \
        xfce \
        xfce4-goodies \
        slim \
        dbus \
        polkit \
        xorg \
        xf86-video-scfb \
        xf86-input-keyboard \
        xf86-input-mouse

    # Enable services
    printf "%b\n" "${CYAN}Enabling required services...${RC}"
    "$ESCALATION_TOOL" sysrc dbus_enable=YES
    "$ESCALATION_TOOL" sysrc slim_enable=YES
    "$ESCALATION_TOOL" sysrc moused_enable=YES

    # Start services
    "$ESCALATION_TOOL" service dbus start
    "$ESCALATION_TOOL" service moused start

    # Configure SLiM for XFCE
    printf "%b\n" "${CYAN}Configuring SLiM for XFCE...${RC}"
    
    # Create SLiM configuration
    cat > /usr/local/etc/slim.conf << 'EOF'
# SLiM configuration file
default_path        /bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
default_xserver     /usr/local/bin/X
xserver_arguments   -nolisten tcp vt05
numlock
daemon              yes
xauth_path         /usr/local/bin/xauth
authfile           /var/run/slim.auth
auth_file_max_age  5
errorlog           /var/log/slim.log
sessiondir         /usr/local/share/xsessions
hidecursor         false
logfile            /var/log/slim.log
lockfile           /var/run/slim.lock
login_cmd          exec /bin/sh -l ~/.xinitrc %session
halt_cmd           /sbin/shutdown -h now
reboot_cmd         /sbin/shutdown -r now
suspend_cmd        /usr/sbin/acpiconf -s 3
console_cmd        /usr/local/bin/xterm -C -fg white -bg black +sb -g %dx%d+%d+%d -fn %dx%d -T ""
screenshot_cmd     /usr/local/bin/import -window root /slim.png
welcome_msg        Welcome to %host
session_msg        Session:
default_user       ""
focus_password     no
auto_login         no
current_theme      default
lock_timeout       300
msg_font           unifont
msg_color          #ffffff
msg_color2         #000000
msg_x              50
msg_y              35
msg_width          400
msg_height         50
msg_align          center
password_color     #ffffff
password_x         50
password_y         50
password_align     center
input_color        #000000
input_font         unifont
input_x            50
input_y            70
input_width        200
input_height       30
input_align        center
input_cursor_color #ffffff
input_cursor_x     50
input_cursor_y     70
input_cursor_width 200
input_cursor_height 30
EOF

    # Create .xinitrc for XFCE
    printf "%b\n" "${CYAN}Creating .xinitrc for XFCE...${RC}"
    cat > "$HOME/.xinitrc" << 'EOF'
#!/bin/sh
# .xinitrc for XFCE
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Start XFCE
exec startxfce4
EOF

    # Make .xinitrc executable
    chmod +x "$HOME/.xinitrc"

    # Create XFCE session file
    printf "%b\n" "${CYAN}Creating XFCE session file...${RC}"
    mkdir -p /usr/local/share/xsessions
    cat > /usr/local/share/xsessions/xfce.desktop << 'EOF'
[Desktop Entry]
Name=XFCE Session
Comment=Use this session to run XFCE as your desktop environment
Exec=startxfce4
Type=Application
EOF

    # Set proper permissions
    chmod 644 /usr/local/share/xsessions/xfce.desktop

    printf "%b\n" "${GREEN}XFCE installed and configured successfully!${RC}"
    printf "%b\n" "${CYAN}Reboot your system to start using XFCE desktop environment.${RC}"
    printf "%b\n" "${CYAN}You can select XFCE from the login manager (SLiM).${RC}"
    printf "%b\n" "${YELLOW}If you still have issues, try logging in via SSH and running: startx${RC}"
}

checkEnv
installXFCE
