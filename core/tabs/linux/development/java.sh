#!/bin/sh -e

. ../common-script.sh

installJava() {
	printf "%b\n" "${YELLOW}Installing Java (OpenJDK LTS)...${RC}"

	case "$PACKAGER" in
		pacman)
			"$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm jdk-openjdk
			;;
		apt-get|nala)
			"$ESCALATION_TOOL" "$PACKAGER" update
			"$ESCALATION_TOOL" "$PACKAGER" install -y default-jdk
			;;
		dnf)
			if ! "$ESCALATION_TOOL" "$PACKAGER" -y install java-21-openjdk-devel; then
				"$ESCALATION_TOOL" "$PACKAGER" -y install java-17-openjdk-devel
			fi
			;;
		zypper)
			if ! "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install java-21-openjdk-devel; then
				"$ESCALATION_TOOL" "$PACKAGER" --non-interactive install java-17-openjdk-devel
			fi
			;;
		apk)
			if ! "$ESCALATION_TOOL" "$PACKAGER" add openjdk21-jdk; then
				"$ESCALATION_TOOL" "$PACKAGER" add openjdk17-jdk
			fi
			;;
		xbps-install)
			if ! "$ESCALATION_TOOL" "$PACKAGER" -Sy openjdk17; then
				"$ESCALATION_TOOL" "$PACKAGER" -Sy openjdk11
			fi
			;;
		eopkg)
			if ! "$ESCALATION_TOOL" "$PACKAGER" install -y openjdk-21; then
				"$ESCALATION_TOOL" "$PACKAGER" install -y openjdk-17
			fi
			;;
		*)
			# Best-effort generic fallbacks
			if ! "$ESCALATION_TOOL" "$PACKAGER" install -y default-jdk; then
				"$ESCALATION_TOOL" "$PACKAGER" install -y openjdk
			fi
			;;
	esac

	printf "%b\n" "${GREEN}Java (OpenJDK) installation complete.${RC}"
}

checkEnv
installJava


