#!/usr/bin/env pwsh

# OSUTIL - PowerShell Version
# A menu-driven system setup and maintenance tool

param(
    [string]$Config,
    [string]$Theme = "Default",
    [switch]$SkipConfirmation,
    [switch]$OverrideValidation,
    [switch]$SizeBypass,
    [switch]$Mouse,
    [switch]$BypassRoot
)

# ANSI color codes for theming
$Themes = @{
    Default = @{
        Primary = "`e[36m"      # Cyan
        Secondary = "`e[33m"    # Yellow
        Success = "`e[32m"      # Green
        Warning = "`e[33m"      # Yellow
        Error = "`e[31m"        # Red
        Info = "`e[34m"         # Blue
        Reset = "`e[0m"         # Reset
    }
    Dark = @{
        Primary = "`e[95m"      # Magenta
        Secondary = "`e[94m"    # Blue
        Success = "`e[92m"      # Light Green
        Warning = "`e[93m"      # Light Yellow
        Error = "`e[91m"        # Light Red
        Info = "`e[96m"         # Light Cyan
        Reset = "`e[0m"         # Reset
    }
}

$CurrentTheme = $Themes[$Theme]
if (-not $CurrentTheme) {
    $CurrentTheme = $Themes["Default"]
}

# Helper functions for colored output
function Write-Color {
    param(
        [string]$Text,
        [string]$Color = "Primary"
    )
    Write-Host "$($CurrentTheme[$Color])$Text$($CurrentTheme.Reset)" -NoNewline
}

function Write-ColorLine {
    param(
        [string]$Text,
        [string]$Color = "Primary"
    )
    Write-Host "$($CurrentTheme[$Color])$Text$($CurrentTheme.Reset)"
}

function Write-Success { param([string]$Text) Write-ColorLine $Text "Success" }
function Write-Warning { param([string]$Text) Write-ColorLine $Text "Warning" }
function Write-Error { param([string]$Text) Write-ColorLine $Text "Error" }
function Write-Info { param([string]$Text) Write-ColorLine $Text "Info" }

# Clear screen and show header
function Show-Header {
    Clear-Host
    Write-ColorLine "╔══════════════════════════════════════════════════════════════╗" "Primary"
    Write-ColorLine "║                    OSUTIL - PowerShell Edition              ║" "Primary"
    Write-ColorLine "║              System Setup and Maintenance Tool              ║" "Primary"
    Write-ColorLine "╚══════════════════════════════════════════════════════════════╝" "Primary"
    Write-Host ""
}

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TabsDir = Join-Path $ScriptDir "core\tabs"

# Load tab configuration
function Load-TabConfiguration {
    $tabsConfigPath = Join-Path $TabsDir "tabs.toml"
    if (Test-Path $tabsConfigPath) {
        $content = Get-Content $tabsConfigPath -Raw
        $directories = $content -split "`n" | Where-Object { $_ -match 'directories\s*=\s*\[(.*)\]' }
        if ($directories) {
            $dirs = $directories[0] -replace '.*\[(.*)\].*', '$1' -split ',' | ForEach-Object { $_.Trim().Trim('"') }
            return $dirs
        }
    }
    return @("windows", "linux", "macos")
}

# Load tab data from a specific directory
function Load-TabData {
    param([string]$TabPath)
    
    $tabDataPath = Join-Path $TabPath "tab_data.toml"
    if (Test-Path $tabDataPath) {
        $content = Get-Content $tabDataPath -Raw
        $tabData = @{}
        
        # Parse TOML-like structure (simplified)
        $lines = $content -split "`n"
        foreach ($line in $lines) {
            if ($line -match '^(\w+)\s*=\s*"([^"]*)"') {
                $tabData[$matches[1]] = $matches[2]
            }
        }
        return $tabData
    }
    return @{}
}

# Get available scripts in a directory
function Get-ScriptsInDirectory {
    param([string]$Directory)
    
    $scripts = @()
    if (Test-Path $Directory) {
        $ps1Files = Get-ChildItem -Path $Directory -Filter "*.ps1" | Sort-Object Name
        foreach ($file in $ps1Files) {
            $scripts += @{
                Name = $file.BaseName
                Path = $file.FullName
                Description = Get-ScriptDescription $file.FullName
            }
        }
    }
    return $scripts
}

# Extract description from script (look for comment at top)
function Get-ScriptDescription {
    param([string]$ScriptPath)
    
    try {
        $firstLine = Get-Content $ScriptPath -TotalCount 1
        if ($firstLine -match '^#\s*(.+)') {
            return $matches[1].Trim()
        }
    }
    catch {
        # Ignore errors
    }
    return "No description available"
}

# Show main menu
function Show-MainMenu {
    Show-Header
    Write-ColorLine "Available Categories:" "Secondary"
    Write-Host ""
    
    $tabs = Load-TabConfiguration
    for ($i = 0; $i -lt $tabs.Count; $i++) {
        $tab = $tabs[$i]
        $tabPath = Join-Path $TabsDir $tab
        $tabData = Load-TabData $tabPath
        
        $displayName = if ($tabData.ContainsKey("name")) { $tabData["name"] } else { $tab }
        Write-Color "  [$($i + 1)] " "Primary"
        Write-Host "$displayName"
        
        if ($tabData.ContainsKey("description")) {
            Write-Color "      " "Primary"
            Write-Host $tabData["description"]
        }
        Write-Host ""
    }
    
    Write-ColorLine "  [0] Exit" "Warning"
    Write-Host ""
    Write-Color "Select a category (0-$($tabs.Count)): " "Secondary"
}

# Show submenu for a specific tab
function Show-SubMenu {
    param([string]$TabName)
    
    Show-Header
    Write-ColorLine "Category: $TabName" "Secondary"
    Write-Host ""
    
    $tabPath = Join-Path $TabsDir $TabName
    $subDirs = Get-ChildItem -Path $tabPath -Directory | Sort-Object Name
    
    if ($subDirs.Count -eq 0) {
        # No subdirectories, show scripts directly
        $scripts = Get-ScriptsInDirectory $tabPath
        Show-ScriptsMenu $scripts $TabName
        return
    }
    
    Write-ColorLine "Available Subcategories:" "Secondary"
    Write-Host ""
    
    for ($i = 0; $i -lt $subDirs.Count; $i++) {
        $subDir = $subDirs[$i]
        $subTabData = Load-TabData $subDir.FullName
        
        $displayName = if ($subTabData.ContainsKey("name")) { $subTabData["name"] } else { $subDir.Name }
        Write-Color "  [$($i + 1)] " "Primary"
        Write-Host "$displayName"
        
        if ($subTabData.ContainsKey("description")) {
            Write-Color "      " "Primary"
            Write-Host $subTabData["description"]
        }
        Write-Host ""
    }
    
    Write-ColorLine "  [0] Back to Main Menu" "Warning"
    Write-Host ""
    Write-Color "Select a subcategory (0-$($subDirs.Count)): " "Secondary"
}

# Show scripts menu
function Show-ScriptsMenu {
    param([array]$Scripts, [string]$CategoryName)
    
    Show-Header
    Write-ColorLine "Category: $CategoryName" "Secondary"
    Write-Host ""
    
    if ($Scripts.Count -eq 0) {
        Write-Warning "No scripts found in this category."
        Write-Host ""
        Write-Color "Press any key to continue..." "Secondary"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    Write-ColorLine "Available Scripts:" "Secondary"
    Write-Host ""
    
    for ($i = 0; $i -lt $Scripts.Count; $i++) {
        $script = $Scripts[$i]
        Write-Color "  [$($i + 1)] " "Primary"
        Write-Host "$($script.Name)"
        Write-Color "      " "Primary"
        Write-Host $script.Description
        Write-Host ""
    }
    
    Write-ColorLine "  [0] Back" "Warning"
    Write-Host ""
    Write-Color "Select a script (0-$($Scripts.Count)): " "Secondary"
}

# Execute a script
function Invoke-Script {
    param([string]$ScriptPath, [string]$ScriptName)
    
    Show-Header
    Write-ColorLine "Executing: $ScriptName" "Secondary"
    Write-Host ""
    
    if (-not $SkipConfirmation) {
        Write-Color "Do you want to execute this script? (y/N): " "Warning"
        $response = Read-Host
        if ($response -notmatch '^[Yy]') {
            Write-Info "Script execution cancelled."
            Start-Sleep -Seconds 2
            return
        }
    }
    
    Write-Info "Starting script execution..."
    Write-Host ""
    
    try {
        # Execute the script in the current scope
        & $ScriptPath
        Write-Host ""
        Write-Success "Script completed successfully!"
    }
    catch {
        Write-Host ""
        Write-Error "Script execution failed: $($_.Exception.Message)"
    }
    
    Write-Host ""
    Write-Color "Press any key to continue..." "Secondary"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Main application loop
function Start-Application {
    while ($true) {
        Show-MainMenu
        $choice = Read-Host
        
        if ($choice -eq "0") {
            Write-Info "Goodbye!"
            break
        }
        
        $tabs = Load-TabConfiguration
        $tabIndex = [int]$choice - 1
        
        if ($tabIndex -ge 0 -and $tabIndex -lt $tabs.Count) {
            $selectedTab = $tabs[$tabIndex]
            $tabPath = Join-Path $TabsDir $selectedTab
            
            if (-not (Test-Path $tabPath)) {
                Write-Error "Category '$selectedTab' not found."
                Start-Sleep -Seconds 2
                continue
            }
            
            # Check if there are subdirectories
            $subDirs = Get-ChildItem -Path $tabPath -Directory
            
            if ($subDirs.Count -gt 0) {
                # Show submenu
                while ($true) {
                    Show-SubMenu $selectedTab
                    $subChoice = Read-Host
                    
                    if ($subChoice -eq "0") {
                        break
                    }
                    
                    $subIndex = [int]$subChoice - 1
                    if ($subIndex -ge 0 -and $subIndex -lt $subDirs.Count) {
                        $selectedSubDir = $subDirs[$subIndex]
                        $scripts = Get-ScriptsInDirectory $selectedSubDir.FullName
                        
                        while ($true) {
                            Show-ScriptsMenu $scripts "$selectedTab > $($selectedSubDir.Name)"
                            $scriptChoice = Read-Host
                            
                            if ($scriptChoice -eq "0") {
                                break
                            }
                            
                            $scriptIndex = [int]$scriptChoice - 1
                            if ($scriptIndex -ge 0 -and $scriptIndex -lt $scripts.Count) {
                                $script = $scripts[$scriptIndex]
                                Invoke-Script $script.Path $script.Name
                            }
                        }
                    }
                }
            }
            else {
                # Show scripts directly
                $scripts = Get-ScriptsInDirectory $tabPath
                
                while ($true) {
                    Show-ScriptsMenu $scripts $selectedTab
                    $scriptChoice = Read-Host
                    
                    if ($scriptChoice -eq "0") {
                        break
                    }
                    
                    $scriptIndex = [int]$scriptChoice - 1
                    if ($scriptIndex -ge 0 -and $scriptIndex -lt $scripts.Count) {
                        $script = $scripts[$scriptIndex]
                        Invoke-Script $script.Path $script.Name
                    }
                }
            }
        }
    }
}

# Check if running as administrator (if needed)
if (-not $BypassRoot) {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Warning "Some scripts may require administrator privileges."
        Write-Color "Continue anyway? (y/N): " "Warning"
        $response = Read-Host
        if ($response -notmatch '^[Yy]') {
            exit 0
        }
    }
}

# Start the application
try {
    Start-Application
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}