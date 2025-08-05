#!/bin/bash

# OSUTIL - Bash Version
# A menu-driven system setup and maintenance tool

# Colors for theming
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Theme support
THEME=${1:-"Default"}
SKIP_CONFIRMATION=${2:-"false"}

# Color functions
print_color() {
    local color=$1
    local text=$2
    echo -e "${color}${text}${NC}"
}

print_success() { print_color $GREEN "$1"; }
print_warning() { print_color $YELLOW "$1"; }
print_error() { print_color $RED "$1"; }
print_info() { print_color $BLUE "$1"; }
print_primary() { print_color $CYAN "$1"; }

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TABS_DIR="$SCRIPT_DIR/core/tabs"

# Show header
show_header() {
    clear
    print_primary "╔══════════════════════════════════════════════════════════════╗"
    print_primary "║                    OSUTIL - Bash Edition                    ║"
    print_primary "║              System Setup and Maintenance Tool              ║"
    print_primary "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# Load tab configuration
load_tab_configuration() {
    local tabs_config_path="$TABS_DIR/tabs.toml"
    if [[ -f "$tabs_config_path" ]]; then
        # Simple TOML parsing for directories
        local content=$(cat "$tabs_config_path")
        if [[ $content =~ directories[[:space:]]*=[[:space:]]*\[(.*)\] ]]; then
            local dirs_str="${BASH_REMATCH[1]}"
            # Split by comma and clean up
            IFS=',' read -ra DIRS <<< "$dirs_str"
            for dir in "${DIRS[@]}"; do
                echo "$dir" | sed 's/^[[:space:]]*"//;s/"[[:space:]]*$//'
            done
        fi
    else
        echo "windows"
        echo "linux"
        echo "macos"
    fi
}

# Load tab data
load_tab_data() {
    local tab_path=$1
    local tab_data_path="$tab_path/tab_data.toml"
    
    if [[ -f "$tab_data_path" ]]; then
        # Simple TOML parsing
        local name=$(grep '^name[[:space:]]*=' "$tab_data_path" | sed 's/^name[[:space:]]*=[[:space:]]*"\(.*\)"/\1/')
        local description=$(grep '^description[[:space:]]*=' "$tab_data_path" | sed 's/^description[[:space:]]*=[[:space:]]*"\(.*\)"/\1/')
        echo "$name|$description"
    else
        echo "||"
    fi
}

# Get scripts in directory
get_scripts_in_directory() {
    local directory=$1
    local scripts=()
    
    if [[ -d "$directory" ]]; then
        while IFS= read -r -d '' file; do
            local name=$(basename "$file" .ps1)
            local description=$(get_script_description "$file")
            scripts+=("$name|$file|$description")
        done < <(find "$directory" -maxdepth 1 -name "*.ps1" -print0 | sort -z)
    fi
    
    printf '%s\n' "${scripts[@]}"
}

# Get script description
get_script_description() {
    local script_path=$1
    if [[ -f "$script_path" ]]; then
        local first_line=$(head -n 1 "$script_path")
        if [[ $first_line =~ ^#[[:space:]]*(.+)$ ]]; then
            echo "${BASH_REMATCH[1]}"
        else
            echo "No description available"
        fi
    else
        echo "No description available"
    fi
}

# Show main menu
show_main_menu() {
    show_header
    print_info "Available Categories:"
    echo ""
    
    local tabs=($(load_tab_configuration))
    local i=1
    for tab in "${tabs[@]}"; do
        local tab_path="$TABS_DIR/$tab"
        local tab_data=$(load_tab_data "$tab_path")
        IFS='|' read -r name description <<< "$tab_data"
        
        local display_name=${name:-$tab}
        print_primary "  [$i] $display_name"
        if [[ -n "$description" ]]; then
            print_primary "      $description"
        fi
        echo ""
        ((i++))
    done
    
    print_warning "  [0] Exit"
    echo ""
    print_info "Select a category (0-${#tabs[@]}): "
}

# Show submenu
show_submenu() {
    local tab_name=$1
    show_header
    print_info "Category: $tab_name"
    echo ""
    
    local tab_path="$TABS_DIR/$tab_name"
    local subdirs=($(find "$tab_path" -maxdepth 1 -type d | sort | tail -n +2))
    
    if [[ ${#subdirs[@]} -eq 0 ]]; then
        # No subdirectories, show scripts directly
        local scripts=($(get_scripts_in_directory "$tab_path"))
        show_scripts_menu "${scripts[@]}" "$tab_name"
        return
    fi
    
    print_info "Available Subcategories:"
    echo ""
    
    local i=1
    for subdir in "${subdirs[@]}"; do
        local sub_tab_data=$(load_tab_data "$subdir")
        IFS='|' read -r name description <<< "$sub_tab_data"
        
        local display_name=${name:-$(basename "$subdir")}
        print_primary "  [$i] $display_name"
        if [[ -n "$description" ]]; then
            print_primary "      $description"
        fi
        echo ""
        ((i++))
    done
    
    print_warning "  [0] Back to Main Menu"
    echo ""
    print_info "Select a subcategory (0-${#subdirs[@]}): "
}

# Show scripts menu
show_scripts_menu() {
    local scripts=("$@")
    local category_name=${scripts[-1]}
    unset "scripts[-1]"
    
    show_header
    print_info "Category: $category_name"
    echo ""
    
    if [[ ${#scripts[@]} -eq 0 ]]; then
        print_warning "No scripts found in this category."
        echo ""
        print_info "Press any key to continue..."
        read -n 1
        return
    fi
    
    print_info "Available Scripts:"
    echo ""
    
    local i=1
    for script in "${scripts[@]}"; do
        IFS='|' read -r name path description <<< "$script"
        print_primary "  [$i] $name"
        print_primary "      $description"
        echo ""
        ((i++))
    done
    
    print_warning "  [0] Back"
    echo ""
    print_info "Select a script (0-${#scripts[@]}): "
}

# Execute script
invoke_script() {
    local script_path=$1
    local script_name=$2
    
    show_header
    print_info "Executing: $script_name"
    echo ""
    
    if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
        print_warning "Do you want to execute this script? (y/N): "
        read -r response
        if [[ ! $response =~ ^[Yy]$ ]]; then
            print_info "Script execution cancelled."
            sleep 2
            return
        fi
    fi
    
    print_info "Starting script execution..."
    echo ""
    
    if [[ -f "$script_path" ]]; then
        # Execute the script
        if bash "$script_path"; then
            echo ""
            print_success "Script completed successfully!"
        else
            echo ""
            print_error "Script execution failed!"
        fi
    else
        print_error "Script file not found: $script_path"
    fi
    
    echo ""
    print_info "Press any key to continue..."
    read -n 1
}

# Main application loop
start_application() {
    while true; do
        show_main_menu
        read -r choice
        
        if [[ $choice == "0" ]]; then
            print_info "Goodbye!"
            break
        fi
        
        local tabs=($(load_tab_configuration))
        local tab_index=$((choice - 1))
        
        if [[ $tab_index -ge 0 && $tab_index -lt ${#tabs[@]} ]]; then
            local selected_tab=${tabs[$tab_index]}
            local tab_path="$TABS_DIR/$selected_tab"
            
            if [[ ! -d "$tab_path" ]]; then
                print_error "Category '$selected_tab' not found."
                sleep 2
                continue
            fi
            
            # Check if there are subdirectories
            local subdirs=($(find "$tab_path" -maxdepth 1 -type d | sort | tail -n +2))
            
            if [[ ${#subdirs[@]} -gt 0 ]]; then
                # Show submenu
                while true; do
                    show_submenu "$selected_tab"
                    read -r sub_choice
                    
                    if [[ $sub_choice == "0" ]]; then
                        break
                    fi
                    
                    local sub_index=$((sub_choice - 1))
                    if [[ $sub_index -ge 0 && $sub_index -lt ${#subdirs[@]} ]]; then
                        local selected_subdir=${subdirs[$sub_index]}
                        local scripts=($(get_scripts_in_directory "$selected_subdir"))
                        
                        while true; do
                            show_scripts_menu "${scripts[@]}" "$selected_tab > $(basename "$selected_subdir")"
                            read -r script_choice
                            
                            if [[ $script_choice == "0" ]]; then
                                break
                            fi
                            
                            local script_index=$((script_choice - 1))
                            if [[ $script_index -ge 0 && $script_index -lt ${#scripts[@]} ]]; then
                                local script=${scripts[$script_index]}
                                IFS='|' read -r name path description <<< "$script"
                                invoke_script "$path" "$name"
                            fi
                        done
                    fi
                done
            else
                # Show scripts directly
                local scripts=($(get_scripts_in_directory "$tab_path"))
                
                while true; do
                    show_scripts_menu "${scripts[@]}" "$selected_tab"
                    read -r script_choice
                    
                    if [[ $script_choice == "0" ]]; then
                        break
                    fi
                    
                    local script_index=$((script_choice - 1))
                    if [[ $script_index -ge 0 && $script_index -lt ${#scripts[@]} ]]; then
                        local script=${scripts[$script_index]}
                        IFS='|' read -r name path description <<< "$script"
                        invoke_script "$path" "$name"
                    fi
                done
            fi
        fi
    done
}

# Check if running as root (if needed)
if [[ $EUID -ne 0 ]]; then
    print_warning "Some scripts may require root privileges."
    print_info "Continue anyway? (y/N): "
    read -r response
    if [[ ! $response =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Start the application
start_application