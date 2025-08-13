#!/bin/sh -e

. ../common-script.sh

disable_online_suggestions() {
    printf "%b\n" "${CYAN}Disabling Spotlight network suggestions...${RC}"
    defaults write com.apple.Spotlight SuggestionsEnabled -bool false || true
    defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true || true
    defaults write com.apple.Safari UniversalSearchEnabled -bool false || true
    defaults write com.apple.Safari SuppressSearchSuggestions -bool true || true
    printf "%b\n" "${GREEN}Online suggestions disabled (may require reboot/log out).${RC}"
}

rebuild_index_all() {
    printf "%b\n" "${CYAN}Rebuilding Spotlight index for all mounted volumes...${RC}"
    "$ESCALATION_TOOL" mdutil -Ea || true
}

toggle_index_current() {
    VOL="/"
    printf "%b" "${YELLOW}Toggle indexing for current volume '/': enable (e) / disable (d)? [e/d]: ${RC}"
    read -r ans || ans="e"
    case "$ans" in
        d|D)
            "$ESCALATION_TOOL" mdutil -i off "$VOL" || true
            ;;
        *)
            "$ESCALATION_TOOL" mdutil -i on "$VOL" || true
            ;;
    esac
    "$ESCALATION_TOOL" mdutil -s "$VOL" || true
}

checkEnv
printf "%b\n" "${CYAN}Spotlight tuning options:${RC}"
printf "%b\n" "1) Disable online suggestions"
printf "%b\n" "2) Rebuild index for all volumes"
printf "%b\n" "3) Toggle indexing for current volume (/ )"
printf "%b" "${YELLOW}Choose an option [1-3]: ${RC}"
read -r choice || choice=1
case "$choice" in
    1) disable_online_suggestions ;;
    2) rebuild_index_all ;;
    3) toggle_index_current ;;
    *) disable_online_suggestions ;;
esac


