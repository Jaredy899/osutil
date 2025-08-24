#!/bin/sh -e

. ../common-script.sh

installCommonUtils() {
    printf "%b\n" "${YELLOW}Installing common utilities...${RC}"

    # Install essential utilities
    printf "%b\n" "${CYAN}Installing essential utilities...${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" install -y \
        bash \
        curl \
        wget \
        git \
        vim \
        htop \
        tree \
        tmux \
        screen \
        rsync \
        unzip \
        gtar \
        gmake \
        gcc \
        cmake \
        pkgconf

    printf "%b\n" "${GREEN}Common utilities installed successfully!${RC}"
}

checkEnv
installCommonUtils
