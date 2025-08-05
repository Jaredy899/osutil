# OSUTIL - Bash Edition

A menu-driven system setup and maintenance tool written in Bash, providing the same functionality as the original Rust TUI application.

## Features

- **Menu-driven Interface**: Easy-to-use text-based menu system
- **Colored Output**: ANSI color support for better visual experience
- **Script Organization**: Hierarchical organization of system setup scripts
- **Confirmation Prompts**: Built-in safety confirmations before script execution
- **Cross-platform**: Works on Linux, macOS, and other Unix-like systems
- **No Dependencies**: Only requires Bash and standard Unix tools

## Usage

### Basic Usage

```bash
# Run the main script
./osutil.sh
```

### Command Line Options

```bash
# Skip confirmation prompts
./osutil.sh "Default" "true"

# Use a different theme (not implemented in bash version)
./osutil.sh "Dark" "false"
```

### Available Parameters

- `$1`: Theme to use (Default, Dark) - not fully implemented in bash version
- `$2`: Skip confirmation (true/false)

## Installation

1. **Download the script**: Save `osutil.sh` to your desired location
2. **Make it executable**:
   ```bash
   chmod +x osutil.sh
   ```
3. **Run the script**:
   ```bash
   ./osutil.sh
   ```

## Script Organization

The Bash version expects the same directory structure as the original Rust application:

```
core/
└── tabs/
    ├── tabs.toml
    ├── windows/
    │   ├── tab_data.toml
    │   ├── applications-setup/
    │   │   ├── tab_data.toml
    │   │   └── *.ps1
    │   └── system-setup/
    │       ├── tab_data.toml
    │       └── *.ps1
    ├── linux/
    │   └── *.ps1
    └── macos/
        └── *.ps1
```

### Configuration Files

- `tabs.toml`: Defines the main categories (windows, linux, macos)
- `tab_data.toml`: Contains metadata for each category/subcategory:
  ```toml
  name = "Display Name"
  description = "Description of this category"
  ```

### Script Requirements

- Scripts should be `.ps1` files (PowerShell scripts)
- The first line can contain a description comment: `# Script description`
- Scripts are executed using `bash` (may need modification for PowerShell scripts)

## Advantages of Bash Version

1. **No Compilation Required**: Run directly without building
2. **Easy Modification**: Simple to customize and extend
3. **Universal Compatibility**: Works on virtually all Unix-like systems
4. **No Dependencies**: Only requires Bash and standard tools
5. **Lightweight**: Small file size and fast execution

## Limitations

1. **No Advanced TUI**: Simpler menu system compared to the Rust TUI
2. **Limited Theme Support**: Basic color theming only
3. **Basic Configuration**: Simplified configuration parsing
4. **No Multi-select**: Single script execution only
5. **PowerShell Script Execution**: May need modification to properly execute PowerShell scripts

## Security Considerations

- Scripts are executed using `bash`
- Always review scripts before execution
- Use skip confirmation with caution
- Some scripts may require root privileges

## Troubleshooting

### Permission Issues

If you encounter permission errors:

```bash
# Make script executable
chmod +x osutil.sh

# Run with sudo if needed
sudo ./osutil.sh
```

### Script Execution Issues

If PowerShell scripts don't execute properly:

1. Ensure PowerShell is installed on the system
2. Modify the script execution in `invoke_script()` function:
   ```bash
   # Change from:
   bash "$script_path"
   
   # To:
   pwsh "$script_path"  # or powershell "$script_path"
   ```

### Root Privileges

Some scripts may require root privileges:

```bash
# Run as root
sudo ./osutil.sh
```

## Contributing

To add new scripts:

1. Place your `.ps1` file in the appropriate category directory
2. Add a description comment at the top of your script
3. Optionally create a `tab_data.toml` file for category metadata

## Differences from PowerShell Version

- Uses Bash instead of PowerShell
- Simpler parameter handling
- Different script execution method
- Limited theme support
- More universal compatibility

## License

Same license as the original project (MIT).