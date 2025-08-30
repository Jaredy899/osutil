#!/bin/sh -e

. ../common-script.sh

installZig() {
	case "$ARCH" in
		x86_64) ZIG_ARCH="x86_64" ;;
		aarch64) ZIG_ARCH="aarch64" ;;
		*) printf "%b\n" "${RED}Unsupported architecture for Zig: $ARCH${RC}" ; exit 1 ;;
	esac

	INDEX_JSON=$(curl -fsSL https://ziglang.org/download/index.json)
    # Ensure jq is available for robust JSON parsing
    if ! command_exists jq; then
		case "$PACKAGER" in
			pacman)
				"$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm jq
				;;
			apk)
				"$ESCALATION_TOOL" "$PACKAGER" add jq
				;;
			xbps-install)
				"$ESCALATION_TOOL" "$PACKAGER" -Sy jq
				;;
			*)
				"$ESCALATION_TOOL" "$PACKAGER" install -y jq
				;;
		esac
	fi

    ZIG_KEY="${ZIG_ARCH}-linux"

    # Get the latest 5 stable versions
    VERSIONS=$(printf "%s" "$INDEX_JSON" | jq -r '
      to_entries
      | map(select(.key | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")))
      | sort_by(.key | split(".") | map(tonumber))
      | reverse[0:5]
      | .[].key')

    # Display available versions
    printf "%b\n" "${YELLOW}Available Zig versions:${RC}"
    printf "%b\n" "${CYAN}0) Latest stable (recommended)${RC}"
    i=1
    printf "%s\n" "$VERSIONS" | while IFS= read -r version; do
        printf "%b\n" "${CYAN}$i) $version${RC}"
        i=$((i + 1))
    done

    # Get user selection
    printf "%b" "${YELLOW}Select version to install (0 for latest): ${RC}"
    read -r selection

    # Validate selection
    if [ "$selection" = "0" ] || [ -z "$selection" ]; then
        printf "%b\n" "${YELLOW}Installing latest stable Zig...${RC}"
        URL=$(printf "%s" "$INDEX_JSON" | jq -r --arg key "$ZIG_KEY" '
          [ to_entries
            | map(select(.key | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")))
            | sort_by(.key | split(".") | map(tonumber))
            | reverse[]
            | (.value[$key].tarball // .value.tarball)
          ]
          | map(select(. != null))
          | .[0] // empty')
    else
        # Convert selection to array index (1-based to 0-based)
        version_index=$((selection - 1))
        selected_version=$(printf "%s" "$VERSIONS" | sed -n "${selection}p")

        if [ -z "$selected_version" ]; then
            printf "%b\n" "${RED}Invalid selection. Installing latest stable version.${RC}"
            URL=$(printf "%s" "$INDEX_JSON" | jq -r --arg key "$ZIG_KEY" '
              [ to_entries
                | map(select(.key | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")))
                | sort_by(.key | split(".") | map(tonumber))
                | reverse[]
                | (.value[$key].tarball // .value.tarball)
              ]
              | map(select(. != null))
              | .[0] // empty')
        else
            printf "%b\n" "${YELLOW}Installing Zig $selected_version...${RC}"
            URL=$(printf "%s" "$INDEX_JSON" | jq -r --arg key "$ZIG_KEY" --arg version "$selected_version" '
              .[$version][$key].tarball // .[$version].tarball // empty')
        fi
    fi

    # Last resort: use master (dev) only if no stable tarball found
    if [ -z "$URL" ] || [ "$URL" = "null" ]; then
        URL=$(printf "%s" "$INDEX_JSON" | jq -r --arg key "$ZIG_KEY" '.master[$key].tarball // empty')
    fi

	if [ -z "$URL" ] || [ "$URL" = "null" ]; then
		printf "%b\n" "${RED}Failed to resolve a Zig download URL from index.json.${RC}"
		exit 1
	fi

	PKG="/tmp/$(basename "$URL")"
	curl -fsSL "$URL" -o "$PKG"

	DEST_DIR="/opt/zig"
    EXTRACTED_NAME=$(basename "$URL" .tar.xz)
    EXTRACTED_DIR="${DEST_DIR}/${EXTRACTED_NAME}"

	"$ESCALATION_TOOL" mkdir -p "$DEST_DIR"
	# Remove any existing dir for this version/arch
	"$ESCALATION_TOOL" rm -rf "$EXTRACTED_DIR"

	printf "%b\n" "${YELLOW}Extracting Zig to ${DEST_DIR}...${RC}"
	"$ESCALATION_TOOL" tar -C "$DEST_DIR" -xJf "$PKG"
	rm -f "$PKG"

	# Symlink /usr/local/bin/zig
	"$ESCALATION_TOOL" mkdir -p /usr/local/bin
	"$ESCALATION_TOOL" ln -sf "${EXTRACTED_DIR}/zig" /usr/local/bin/zig

	printf "%b\n" "${GREEN}Zig installed from: ${URL}${RC}"
}

checkEnv
installZig


