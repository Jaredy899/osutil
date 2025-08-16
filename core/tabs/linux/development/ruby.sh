#!/bin/sh -e

. ../common-script.sh

installRuby() {
	printf "%b\n" "${YELLOW}Installing Ruby...${RC}"

	case "$PACKAGER" in
		pacman)
			"$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm ruby
			;;
		apt-get|nala)
			"$ESCALATION_TOOL" "$PACKAGER" update
			if ! "$ESCALATION_TOOL" "$PACKAGER" install -y ruby-full; then
				"$ESCALATION_TOOL" "$PACKAGER" install -y ruby
			fi
			;;
		dnf)
			"$ESCALATION_TOOL" "$PACKAGER" -y install ruby
			;;
		zypper)
			"$ESCALATION_TOOL" "$PACKAGER" --non-interactive install ruby
			;;
		apk)
			"$ESCALATION_TOOL" "$PACKAGER" add ruby
			;;
		xbps-install)
			"$ESCALATION_TOOL" "$PACKAGER" -Sy ruby
			;;
		eopkg)
			"$ESCALATION_TOOL" "$PACKAGER" install -y ruby
			;;
		*)
			"$ESCALATION_TOOL" "$PACKAGER" install -y ruby
			;;
	esac

	printf "%b\n" "${GREEN}Ruby installation complete.${RC}"
}

checkEnv
installRuby


