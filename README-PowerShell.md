# OSUTIL - PowerShell Edition

A menu-driven system setup and maintenance tool written in PowerShell, providing the same functionality as the original Rust TUI application.

## Features

- **Menu-driven Interface**: Easy-to-use text-based menu system
- **Colored Output**: ANSI color support for better visual experience
- **Script Organization**: Hierarchical organization of system setup scripts
- **Confirmation Prompts**: Built-in safety confirmations before script execution
- **Cross-platform**: Works on Windows, Linux, and macOS (PowerShell Core)
- **Theme Support**: Multiple color themes available

## Usage

### Basic Usage

```powershell
# Run the main script
.\osutil.ps1
```

### Command Line Options

```powershell
# Skip confirmation prompts
.\osutil.ps1 -SkipConfirmation

# Use a different theme
.\osutil.ps1 -Theme Dark

# Bypass root/admin check
.\osutil.ps1 -BypassRoot

# Override validation (UNSAFE)
.\osutil.ps1 -OverrideValidation
```

### Available Parameters

- `-Config`: Path to configuration file (not implemented in this version)
- `-Theme`: Color theme to use (Default, Dark)
- `-SkipConfirmation`: Skip confirmation prompts before executing scripts
- `-OverrideValidation`: Show all options, disregarding compatibility checks (UNSAFE)
- `-SizeBypass`: Bypass terminal size limit (not implemented in this version)
- `-Mouse`: Enable mouse interaction (not implemented in this version)
- `-BypassRoot`: Bypass root user check

## Installation

1. **Download the script**: Save `osutil.ps1` to your desired location
2. **Set execution policy** (if needed):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. **Run the script**:
   ```powershell
   .\osutil.ps1
   ```

## Script Organization

The PowerShell version expects the same directory structure as the original Rust application:

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

- Scripts should be `.ps1` files
- The first line can contain a description comment: `# Script description`
- Scripts are executed in the current PowerShell session

## Advantages of PowerShell Version

1. **No Compilation Required**: Run directly without building
2. **Easy Modification**: Simple to customize and extend
3. **Native PowerShell**: Better integration with PowerShell ecosystem
4. **Cross-platform**: Works with PowerShell Core on multiple platforms
5. **No Dependencies**: Only requires PowerShell itself

## Limitations

1. **No Advanced TUI**: Simpler menu system compared to the Rust TUI
2. **Limited Mouse Support**: No mouse interaction in this version
3. **Basic Configuration**: Simplified configuration parsing
4. **No Multi-select**: Single script execution only

## Security Considerations

- Scripts are executed in the current PowerShell session
- Always review scripts before execution
- Use `-SkipConfirmation` with caution
- Some scripts may require administrator privileges

## Troubleshooting

### Execution Policy Issues

If you encounter execution policy errors:

```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Permission Issues

Some scripts may require administrator privileges:

```powershell
# Run PowerShell as Administrator
Start-Process powershell -Verb RunAs
```

### Script Not Found

Ensure the script is in the correct directory structure and has the proper permissions.

## Contributing

To add new scripts:

1. Place your `.ps1` file in the appropriate category directory
2. Add a description comment at the top of your script
3. Optionally create a `tab_data.toml` file for category metadata

## License

Same license as the original project (MIT).