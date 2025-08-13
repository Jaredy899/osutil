#!/bin/sh -e

. ../common-script.sh

apply_privacy_settings() {
    printf "%b\n" "${CYAN}Applying privacy baseline...${RC}"

    # Diagnostics & analytics
    "$ESCALATION_TOOL" defaults write com.apple.SubmitDiagInfo AutoSubmit -bool false || true
    "$ESCALATION_TOOL" defaults write com.apple.SubmitDiagInfo ThirdPartyDataSubmit -bool false || true

    # Personalized ads (may be ignored on some versions)
    defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false || true

    # Siri/Spotlight/Safari online suggestions
    defaults write com.apple.Spotlight SuggestionsEnabled -bool false || true
    defaults write com.apple.Safari UniversalSearchEnabled -bool false || true
    defaults write com.apple.Safari SuppressSearchSuggestions -bool true || true

    printf "%b\n" "${GREEN}Privacy preferences written (some may require logout/restart to take effect).${RC}"
}

offer_location_services_help() {
    printf "%b" "${YELLOW}Open Location Services privacy settings to review permissions? [y/N]: ${RC}"
    read -r resp || resp=""
    case "$resp" in
        y|Y)
            open "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices" || true
            ;;
        *)
            ;;
    esac
}

report_changes() {
    printf "%b\n" "${GREEN}Applied settings:${RC}"
    printf "%b\n" "- Diagnostics auto-submit: disabled"
    printf "%b\n" "- Third-party diagnostics: disabled"
    printf "%b\n" "- Personalized ads: requested disabled"
    printf "%b\n" "- Spotlight/Safari online suggestions: disabled"
}

checkEnv
apply_privacy_settings
offer_location_services_help
report_changes


