#!/bin/sh -e

. ../common-script.sh

fixVMMouse() {
    printf "%b\n" "${YELLOW}Fixing mouse issues in Proxmox VM...${RC}"

    # Check current mouse status
    printf "%b\n" "${CYAN}Checking current mouse configuration...${RC}"
    ls -la /dev/sysmouse 2>/dev/null || printf "%b\n" "${RED}/dev/sysmouse not found${RC}"
    service moused status || printf "%b\n" "${RED}moused service not running${RC}"

    # Install additional mouse drivers
    printf "%b\n" "${CYAN}Installing additional mouse drivers...${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" install -y \
        xf86-input-evdev \
        xf86-input-synaptics \
        xf86-input-vmmouse

    # Create alternative X configuration for VM mouse
    printf "%b\n" "${CYAN}Creating alternative X configuration for VM mouse...${RC}"
    cat > /usr/local/share/X11/xorg.conf.d/20-vm-mouse.conf << 'EOF'
Section "InputDevice"
    Identifier  "VMouse0"
    Driver      "vmmouse"
    Option      "Device" "/dev/sysmouse"
    Option      "Protocol" "auto"
    Option      "ZAxisMapping" "4 5 6 7"
EndSection

Section "InputDevice"
    Identifier  "EvMouse0"
    Driver      "evdev"
    Option      "Device" "/dev/input/event0"
    Option      "Protocol" "auto"
EndSection

Section "ServerLayout"
    Identifier     "VM Layout"
    InputDevice    "VMouse0" "CorePointer"
    InputDevice    "EvMouse0" "SendCoreEvents"
EndSection
EOF

    # Enable moused with specific options for VM
    printf "%b\n" "${CYAN}Configuring moused for VM...${RC}"
    "$ESCALATION_TOOL" sysrc moused_enable=YES
    "$ESCALATION_TOOL" sysrc moused_flags="-p /dev/psm0 -t auto"
    "$ESCALATION_TOOL" service moused restart

    # Create a test script to check mouse devices
    printf "%b\n" "${CYAN}Creating mouse test script...${RC}"
    cat > /tmp/test-mouse.sh << 'EOF'
#!/bin/sh
echo "=== Mouse Device Check ==="
echo "Available mouse devices:"
ls -la /dev/psm* /dev/sysmouse /dev/input/event* 2>/dev/null || echo "No mouse devices found"

echo -e "\n=== Mouse Service Status ==="
service moused status

echo -e "\n=== X Input Devices ==="
if command -v xinput >/dev/null 2>&1; then
    xinput list
else
    echo "xinput not available"
fi

echo -e "\n=== Proxmox VM Settings ==="
echo "Make sure in Proxmox VM settings:"
echo "1. Hardware -> Mouse -> Enable 'tablet' mode"
echo "2. Options -> Qemu Guest Agent -> Enable"
echo "3. Options -> Display -> Enable 'SPICE' or 'VNC'"
EOF

    chmod +x /tmp/test-mouse.sh

    printf "%b\n" "${GREEN}Mouse configuration updated for Proxmox VM!${RC}"
    printf "%b\n" "${YELLOW}Please check your Proxmox VM settings:${RC}"
    printf "%b\n" "${YELLOW}1. Go to VM settings in Proxmox web interface${RC}"
    printf "%b\n" "${YELLOW}2. Hardware -> Mouse -> Enable 'tablet' mode${RC}"
    printf "%b\n" "${YELLOW}3. Options -> Qemu Guest Agent -> Enable${RC}"
    printf "%b\n" "${YELLOW}4. Reboot the VM after making these changes${RC}"
    printf "%b\n" "${CYAN}Run /tmp/test-mouse.sh to check mouse status${RC}"
}

checkEnv
fixVMMouse
