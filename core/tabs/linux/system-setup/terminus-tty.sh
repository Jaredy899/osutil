#!/bin/sh -e

. ../common-script.sh

InstallTermiusFonts() {
    if [ ! -f "/usr/share/kbd/consolefonts/ter-c18b.psf.gz" ] && 
       [ ! -f "/usr/share/consolefonts/Uni3-TerminusBold18x10.psf.gz" ] && 
       [ ! -f "/usr/lib/kbd/consolefonts/ter-p32n.psf.gz" ]; then
    printf "%b\n" "${YELLOW}Installing Terminus Fonts...${RC}"
        case "$PACKAGER" in
            pacman)
                installPkg terminus-font
                ;;
            apt-get|nala)
                installPkg fonts-terminus
                ;;
            dnf)
                installPkg terminus-fonts-console
                ;;            
            xbps-install)
                installPkg terminus-font
                ;;
            eopkg)
                installPkg font-terminus-console
                ;;
            moss)
                installPkg terminus-font
                ;;
            zypper)
                installPkg terminus-bitmap-fonts
                ;;
            apk)
                installPkg font-terminus
                ;;
            *)
                unsupportedPackager
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Terminus Fonts is already installed.${RC}"
    fi
}

SetTermiusFonts() {
        case "$PACKAGER" in
            pacman|xbps-install|dnf|eopkg|zypper)
                printf "%b\n" "${YELLOW}Updating FONT= line in /etc/vconsole.conf...${RC}"
                "$ESCALATION_TOOL" sed -i 's/^FONT=.*/FONT=ter-v18b/' /etc/vconsole.conf
                if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
                   "$ESCALATION_TOOL" setfont -C /dev/tty1 ter-v18b
                fi
                printf "%b\n" "${GREEN}Terminus font set for TTY.${RC}"
                ;;
            apk)
                printf "%b\n" "${YELLOW}Updating console font configuration for Alpine...${RC}"
                if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
                    "$ESCALATION_TOOL" setfont -C /dev/tty1 /usr/share/consolefonts/ter-v18b.psf.gz
                fi
                echo 'consolefont="/usr/share/consolefonts/ter-v18b.psf.gz"' | "$ESCALATION_TOOL" tee /etc/conf.d/consolefont > /dev/null
                "$ESCALATION_TOOL" rc-update add consolefont boot
                printf "%b\n" "${GREEN}Terminus font set for TTY.${RC}"
                ;;
            apt-get|nala)
                printf "%b\n" "${YELLOW}Updating console-setup configuration...${RC}"
                "$ESCALATION_TOOL" sed -i 's/^CODESET=.*/CODESET="guess"/' /etc/default/console-setup
                "$ESCALATION_TOOL" sed -i 's/^FONTFACE=.*/FONTFACE="TerminusBold"/' /etc/default/console-setup
                "$ESCALATION_TOOL" sed -i 's/^FONTSIZE=.*/FONTSIZE="10x18"/' /etc/default/console-setup
                printf "%b\n" "${GREEN}Console-setup configuration updated for Terminus font.${RC}"
                # Editing console-setup requires initramfs to be regenerated
                "$ESCALATION_TOOL" update-initramfs -u
                if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then                    
                   "$ESCALATION_TOOL" setfont -C /dev/tty1 /usr/share/consolefonts/Uni3-TerminusBold18x10.psf.gz
                fi
                printf "%b\n" "${GREEN}Terminus font has been set for TTY.${RC}"
                ;;
            *)
                unsupportedPackager
                ;;
        esac
}

checkEnv
InstallTermiusFonts
SetTermiusFonts
