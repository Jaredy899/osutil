#!/bin/sh -e

. ../common-script.sh
. ./mise-common.sh

installBuildDependencies() {
    printf "%b\n" "${YELLOW}Installing Ruby build dependencies...${RC}"

    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            installPkg build-essential autoconf libssl-dev libyaml-dev zlib1g-dev libffi-dev libgmp-dev rustc
            installPkg patch libreadline6-dev libncurses5-dev libgdbm6 libgdbm-dev libdb-dev || true
            ;;
        dnf)
            if command_exists dnf; then
                installPkg autoconf gcc rust patch make bzip2 openssl-devel libyaml-devel libffi-devel readline-devel gdbm-devel ncurses-devel perl-FindBin
                if "$ESCALATION_TOOL" "$PACKAGER" list zlib-ng-compat-devel >/dev/null 2>&1; then
                    installPkg zlib-ng-compat-devel
                else
                    installPkg zlib-devel
                fi
            else
                installPkg autoconf gcc patch bzip2 openssl-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel tar
            fi
            ;;
        pacman)
            installPkg base-devel rust libffi libyaml openssl zlib
            ;;
        apk)
            installPkg build-base gcc6 patch bzip2 libffi-dev openssl-dev ncurses-dev gdbm-dev zlib-dev readline-dev yaml-dev rust
            ;;
        zypper)
            installPkg gcc make rust patch automake bzip2 libopenssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y -c system.devel
            installPkg autoconf gmp-devel libffi-devel rust openssl-devel yaml-devel zlib-ng-devel
            ;;
        moss)
            installPkg build-essential rust openssl-devel libffi-devel libyaml-devel zlib-devel readline-devel || true
            ;;
        *)
            printf "%b\n" "${YELLOW}Unknown package manager, skipping build dependencies${RC}"
            ;;
    esac
}

installRuby() {
    printf "%b\n" "${YELLOW}Installing Ruby via mise...${RC}"
    installBuildDependencies
    ensureMise
    mise use -g ruby@latest

    printf "%b\n" "${GREEN}Ruby installed via mise. Restart your shell or run: eval \"\$(mise activate bash)\"${RC}"
    printf "%b\n" "${CYAN}Note: For YJIT support in Ruby 3.2+, Rust compiler has been installed.${RC}"
}

checkEnv
checkEscalationTool
installRuby
