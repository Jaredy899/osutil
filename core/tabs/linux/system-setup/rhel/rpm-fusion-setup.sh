#!/bin/sh -e

. ../../common-script.sh

# https://rpmfusion.org/Configuration

installRPMFusion() {
    case "$PACKAGER" in
        dnf)
            if [ "$DTYPE" = "fedora" ]; then
                printf "%b\n" "${YELLOW}This script is for RHEL-based systems. Use the Fedora RPM Fusion script instead.${RC}"
                return 0
            fi
            
            if [ ! -e /etc/yum.repos.d/rpmfusion-free.repo ] || [ ! -e /etc/yum.repos.d/rpmfusion-nonfree.repo ]; then
                printf "%b\n" "${YELLOW}Installing RPM Fusion for RHEL...${RC}"
                
                # Get RHEL version
                rhel_version=$(rpm -E %rhel 2>/dev/null || echo "8")
                
                # Install RPM Fusion repositories
                "$ESCALATION_TOOL" "$PACKAGER" install -y \
                    "https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-${rhel_version}.noarch.rpm" \
                    "https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-${rhel_version}.noarch.rpm"
                
                # Enable PowerTools/CodeReady Builder repository (needed for some RPM Fusion packages)
                if [ "$rhel_version" -ge 8 ]; then
                    if "$ESCALATION_TOOL" "$PACKAGER" repolist | grep -q "powertools"; then
                        "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled powertools
                    elif "$ESCALATION_TOOL" "$PACKAGER" repolist | grep -q "codeready-builder"; then
                        "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled "codeready-builder-for-rhel-${rhel_version}-$(arch)-rpms"
                    fi
                fi
                
                "$ESCALATION_TOOL" "$PACKAGER" install -y rpmfusion-\*-appstream-data
                
                printf "%b\n" "${YELLOW}Do you want to install tainted repositories? [y/N]: ${RC}"
                read -r install_tainted
                case "$install_tainted" in
                    [Yy]*)
                        printf "%b\n" "${YELLOW}Installing RPM Fusion tainted repositories...${RC}"
                        "$ESCALATION_TOOL" "$PACKAGER" install -y rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted
                        "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled rpmfusion-free-tainted
                        "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled rpmfusion-nonfree-tainted
                        printf "%b\n" "${GREEN}RPM Fusion (including tainted repositories) installed and enabled${RC}"
                        ;;
                    *)
                        printf "%b\n" "${BLUE}Skipping tainted repositories${RC}"
                        printf "%b\n" "${GREEN}RPM Fusion installed and enabled${RC}"
                        ;;
                esac
            else
                printf "%b\n" "${GREEN}RPM Fusion already installed${RC}"
            fi
            ;;
        *)
            printf "%b\n" "${RED}Unsupported distribution: $DTYPE${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
installRPMFusion 