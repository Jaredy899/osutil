$esc   = [char]27
$Cyan  = "${esc}[36m"
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Reset = "${esc}[0m"

# Centralized dotfiles repository
$dotfilesRepo = $env:DOTFILES_REPO ?? "https://github.com/Jaredy899/dotfiles.git"
$dotfilesDir = "$env:USERPROFILE\.local\share\dotfiles"

# Ensure clean input handling for TUI environment

# Simple input function that works reliably in TUI
function Read-UserInput {
    param(
        [string]$Prompt = ""
    )
    
    if ($Prompt) {
        Write-Host $Prompt -NoNewline
    }
    
    # Use standard Read-Host which works reliably in most environments
    return Read-Host
}

function Invoke-CloneDotfiles {
    Write-Host "${Yellow}Cloning/updating dotfiles repository...${Reset}"

    # Ensure the parent directory exists
    $parentDir = Split-Path $dotfilesDir -Parent
    if (-not (Test-Path -Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    if (Test-Path -Path $dotfilesDir) {
        Write-Host "${Cyan}Dotfiles directory already exists. Pulling latest changes...${Reset}"
        try {
            Push-Location $dotfilesDir
            git pull
            Pop-Location
        } catch {
            Write-Host "${Red}Failed to update dotfiles repository: $($_.Exception.Message)${Reset}"
            exit 1
        }
    } else {
        try {
            git clone $dotfilesRepo $dotfilesDir
        } catch {
            Write-Host "${Red}Failed to clone dotfiles repository: $($_.Exception.Message)${Reset}"
            exit 1
        }
    }

    Write-Host "${Green}Dotfiles repository ready!${Reset}"
}

function Save-RemoteFile {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$Destination
    )
    # Try BITS first (preferred)
    try {
        Start-BitsTransfer -Source $Url -Destination $Destination -ErrorAction Stop
        return $true
    } catch {
        $err = $_.Exception.Message
        Write-Host "${Yellow}BITS failed: $err${Reset}"
        # Common Win10 error when BITS service is unavailable: 0x800704DD
        # Fallback 1: Invoke-WebRequest
        try {
            Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
            return $true
        } catch {
            Write-Host "${Yellow}Invoke-WebRequest failed: $($_.Exception.Message)${Reset}"
            # Fallback 2: .NET WebClient
            try {
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($Url, $Destination)
                return $true
            } catch {
                Write-Host "${Yellow}.NET WebClient failed: $($_.Exception.Message)${Reset}"
                # Fallback 3: curl.exe (if available)
                try {
                    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
                    if ($null -ne $curl) {
                        & $curl.Path -L -o $Destination $Url
                        if ($LASTEXITCODE -eq 0 -and (Test-Path $Destination)) { return $true }
                    }
                    throw "curl.exe not available or failed"
                } catch {
                    Write-Host "${Red}All download methods failed for: $Url${Reset}"
                    return $false
                }
            }
        }
    }
}

# Everything is now integrated - no external downloads needed!

# Everything is integrated - no external URLs needed!

# Local paths where the scripts will be temporarily downloaded
# $appsScriptPath = "$env:TEMP\apps_install.ps1"  # Now integrated directly
# $fontScriptPath = "$env:TEMP\install_nerd_font.ps1"  # Commented out - using winget nerdfont
# $wingetScriptPath = "$env:TEMP\install_winget.ps1"  # Now integrated directly

function Invoke-DownloadAndRunScript {
    param(
        [string]$url,
        [string]$localPath
    )
    Write-Host "${Yellow}Downloading: $url${Reset}"
    if (Save-RemoteFile -Url $url -Destination $localPath) {
        Write-Host "${Cyan}Running: $localPath${Reset}"
        try { & $localPath } catch { Write-Host "${Red}Script failed: $($_.Exception.Message)${Reset}" }
    } else {
        Write-Host "${Red}Failed to download or run: $url${Reset}"
    }
}

# Clone/update dotfiles repository will happen after Git is installed

# Function to check Winget installation status
function Get-WingetStatus {
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        $installedVersion = (winget --version).Trim('v')
        $latestVersion = (Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/latest").tag_name.Trim('v')
        if ([version]$installedVersion -lt [version]$latestVersion) {
            return "outdated"
        } else {
            return "installed"
        }
    } else {
        return "not installed"
    }
}

# Function to install or update Winget
function Install-Winget {
    Write-Host "${Cyan}=== Checking Winget Installation ===${Reset}"

    # Check Winget installation status
    $isWingetInstalled = Get-WingetStatus

    try {
        if ($isWingetInstalled -eq "installed") {
            Write-Host "`nWinget is already installed and up to date!" -ForegroundColor Green
            return
        } elseif ($isWingetInstalled -eq "outdated") {
            Write-Host "`nWinget is outdated. Proceeding with update..." -ForegroundColor Yellow
        } else {
            Write-Host "`nWinget is not installed. Starting installation..." -ForegroundColor Yellow
        }

        # Gets the computer's information
        Write-Host "Checking system compatibility..." -ForegroundColor Blue
        if ($null -eq $sync.ComputerInfo) {
            $ComputerInfo = Get-ComputerInfo -ErrorAction Stop
        } else {
            $ComputerInfo = $sync.ComputerInfo
        }

        if (($ComputerInfo.WindowsVersion) -lt "1809") {
            Write-Host "Winget is not supported on this version of Windows (Pre-1809)" -ForegroundColor Red
            return
        }

        # Define URLs and paths
        Write-Host "`n=== Downloading Required Components ===" -ForegroundColor Cyan

        $wingetUrl = "https://aka.ms/getwinget"
        $vclibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
        $xamlUrl = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"

        $wingetPackage = "$env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        $vclibsPackage = "$env:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx"
        $xamlPackage = "$env:TEMP\Microsoft.UI.Xaml.2.8.x64.appx"

        Write-Host "Downloading Winget and dependencies..." -ForegroundColor Yellow

        # Download packages
        Start-BitsTransfer -Source $wingetUrl -Destination $wingetPackage -ErrorAction Stop
        Write-Host "Downloaded Winget package successfully!" -ForegroundColor Green

        Start-BitsTransfer -Source $vclibsUrl -Destination $vclibsPackage -ErrorAction Stop
        Write-Host "Downloaded VCLibs package successfully!" -ForegroundColor Green

        Start-BitsTransfer -Source $xamlUrl -Destination $xamlPackage -ErrorAction Stop
        Write-Host "Downloaded XAML package successfully!" -ForegroundColor Green

        Write-Host "`n=== Installing Components ===" -ForegroundColor Cyan
        Write-Host "Installing dependencies..." -ForegroundColor Yellow

        # Install VCLibs
        if (-not (Get-AppxPackage -Name "*VCLibs*" | Where-Object { $_.Version -ge "14.0.33321.0" })) {
            Add-AppxPackage -Path $vclibsPackage
            Write-Host "VCLibs installed successfully!" -ForegroundColor Green
        } else {
            Write-Host "A higher version of VCLibs is already installed." -ForegroundColor Blue
        }

        # Install XAML
        if (-not (Get-AppxPackage -Name "*UI.Xaml*" | Where-Object { $_.Version -ge "2.8.6.0" })) {
            $storeProcess = Get-Process -Name "WinStore.App" -ErrorAction SilentlyContinue
            if ($storeProcess) {
                Write-Host "Closing Microsoft Store to proceed with installation..." -ForegroundColor Yellow
                Stop-Process -Name "WinStore.App" -Force
            }

            Add-AppxPackage -Path $xamlPackage
            Write-Host "UI.Xaml installed successfully!" -ForegroundColor Green
        } else {
            Write-Host "A higher version of UI.Xaml is already installed." -ForegroundColor Blue
        }

        Write-Host "Installing Winget..." -ForegroundColor Yellow
        Add-AppxPackage -Path $wingetPackage

        Write-Host "`n=== Installation Complete ===" -ForegroundColor Cyan
        Write-Host "Winget and all dependencies installed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install Winget or its dependencies. Error: $_" -ForegroundColor Red
    }
}

# Ensure Winget is installed or updated
Write-Host "${Cyan}Checking winget...${Reset}"
Install-Winget

# Applications installation (integrated)
function Install-Apps {
    # List of applications to install using exact Winget identifiers
    $apps = @(
        "Starship.Starship",
        "junegunn.fzf",
        "ajeetdsouza.zoxide",
        "Fastfetch-cli.Fastfetch",
        "sharkdp.bat",
        "GNU.Nano",
        "eza-community.eza",
        "sxyazi.yazi",
        "Microsoft.WindowsTerminal",
        "Microsoft.PowerShell",
        "Neovim.Neovim",
        "Git.Git",
        "DEVCOM.JetBrainsMonoNerdFont",
        "jdx.mise"
    )

    Write-Host "${Cyan}=== Starting Application Installation ===${Reset}"
    foreach ($app in $apps) {
        Write-Host "`n${Yellow}Installing ${Reset}" -NoNewline
        Write-Host "$app" -ForegroundColor Blue -NoNewline
        Write-Host "${Yellow} using Winget...${Reset}"

        try {
            # Run the Winget install command and capture the output
            $installResult = winget install --id $app --accept-package-agreements --accept-source-agreements -e 2>&1

            # Check if the app is already installed and up-to-date
            if ($installResult -match "No available upgrade found" -or $installResult -match "already installed" -or $installResult -match "Up to date") {
                Write-Host "$app is already installed and up to date." -ForegroundColor Blue
            }
            elseif ($LASTEXITCODE -eq 0) {
                Write-Host "$app installed successfully!" -ForegroundColor Green
            } else {
                Write-Host "Failed to install $app. Please check your internet connection or the app name." -ForegroundColor Red
            }
        }
        catch {
            Write-Host "An error occurred while installing $app. Error: $_" -ForegroundColor Red
        }
    }
    Write-Host "`n${Cyan}=== Application Installation Complete ===${Reset}"
}

Write-Host "${Cyan}Installing apps...${Reset}"
Install-Apps

# Clone/update dotfiles repository (now that Git is installed)
Write-Host "${Cyan}Setting up dotfiles...${Reset}"
Invoke-CloneDotfiles

# Nerd Font installation (commented out - using winget nerdfont instead)
# Write-Host "${Cyan}Installing Nerd Font...${Reset}"
# Invoke-DownloadAndRunScript -url $fontScriptUrl -localPath $fontScriptPath

# Set environment variable to suppress mise chpwd warning in PowerShell 5.1
$env:MISE_PWSH_CHPWD_WARNING = "0"

# Function to set environment variable permanently
function Set-PermanentEnvironmentVariable {
    param(
        [string]$Name,
        [string]$Value
    )
    try {
        [Environment]::SetEnvironmentVariable($Name, $Value, [EnvironmentVariableTarget]::User)
        Write-Host "${Green}Set permanent environment variable: $Name=$Value${Reset}"
    } catch {
        Write-Host "${Yellow}Failed to set permanent environment variable $Name: $($_.Exception.Message)${Reset}"
    }
}

# Set the mise warning suppression permanently
Set-PermanentEnvironmentVariable -Name "MISE_PWSH_CHPWD_WARNING" -Value "0"


# Initialize PowerShell profiles (PS5 and PS7)
function Initialize-Profile {
    param(
        [string]$profilePath
    )
    $profileDir = Split-Path $profilePath
    if (-not (Test-Path -Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }

    $sourceProfile = Join-Path $dotfilesDir "powershell\Microsoft.PowerShell_profile.ps1"
    if (Test-Path -Path $sourceProfile) {
        # Remove existing profile if it exists (but backup if it's not already a symlink)
        if (Test-Path -Path $profilePath) {
            $item = Get-Item $profilePath
            if ($item.LinkType -ne "SymbolicLink") {
                $backupPath = "$profilePath.backup"
                Copy-Item -Path $profilePath -Destination $backupPath -Force
                Write-Host "${Yellow}Backed up existing profile to: $backupPath${Reset}"
            }
            Remove-Item -Path $profilePath -Force
        }

        # Create symlink
        try {
            New-Item -ItemType SymbolicLink -Path $profilePath -Target $sourceProfile -Force | Out-Null
            Write-Host "${Green}Profile symlinked: $profilePath${Reset}"
        } catch {
            Write-Host "${Red}Failed to create symlink for profile: $($_.Exception.Message)${Reset}"
        }
    } else {
        Write-Host "${Yellow}PowerShell profile not found in dotfiles repo, skipping...${Reset}"
    }
}

$ps5ProfilePath = "$env:UserProfile\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$ps7ProfilePath = "$env:UserProfile\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
Initialize-Profile -profilePath $ps5ProfilePath
Initialize-Profile -profilePath $ps7ProfilePath

# Config files (fastfetch, starship, mise)
function Initialize-ConfigFiles {
    $userConfigDir = "$env:UserProfile\.config"
    $fastfetchConfigDir = "$userConfigDir\fastfetch"
    $miseConfigDir = "$userConfigDir\mise"
    if (-not (Test-Path -Path $fastfetchConfigDir)) { New-Item -ItemType Directory -Path $fastfetchConfigDir -Force | Out-Null }
    if (-not (Test-Path -Path $miseConfigDir)) { New-Item -ItemType Directory -Path $miseConfigDir -Force | Out-Null }

    # Symlink fastfetch config
    $sourceFastfetchConfig = Join-Path $dotfilesDir "config\fastfetch\windows.jsonc"
    $targetFastfetchConfig = Join-Path $fastfetchConfigDir 'config.jsonc'
    if (Test-Path -Path $sourceFastfetchConfig) {
        if (Test-Path -Path $targetFastfetchConfig) {
            $item = Get-Item $targetFastfetchConfig
            if ($item.LinkType -ne "SymbolicLink") {
                $backupPath = "$targetFastfetchConfig.bak"
                Copy-Item -Path $targetFastfetchConfig -Destination $backupPath -Force
                Write-Host "${Yellow}Backed up existing fastfetch config to: $backupPath${Reset}"
            }
            Remove-Item -Path $targetFastfetchConfig -Force
        }
        try {
            New-Item -ItemType SymbolicLink -Path $targetFastfetchConfig -Target $sourceFastfetchConfig -Force | Out-Null
            Write-Host "${Green}Fastfetch config symlinked.${Reset}"
        } catch {
            Write-Host "${Red}Failed to create symlink for fastfetch config: $($_.Exception.Message)${Reset}"
        }
    } else {
        Write-Host "${Yellow}Fastfetch config not found in dotfiles repo, skipping...${Reset}"
    }

    # Symlink starship config
    $sourceStarshipConfig = Join-Path $dotfilesDir "config\starship.toml"
    $targetStarshipConfig = Join-Path $userConfigDir 'starship.toml'
    if (Test-Path -Path $sourceStarshipConfig) {
        if (Test-Path -Path $targetStarshipConfig) {
            $item = Get-Item $targetStarshipConfig
            if ($item.LinkType -ne "SymbolicLink") {
                $backupPath = "$targetStarshipConfig.bak"
                Copy-Item -Path $targetStarshipConfig -Destination $backupPath -Force
                Write-Host "${Yellow}Backed up existing starship config to: $backupPath${Reset}"
            }
            Remove-Item -Path $targetStarshipConfig -Force
        }
        try {
            New-Item -ItemType SymbolicLink -Path $targetStarshipConfig -Target $sourceStarshipConfig -Force | Out-Null
            Write-Host "${Green}Starship config symlinked.${Reset}"
        } catch {
            Write-Host "${Red}Failed to create symlink for starship config: $($_.Exception.Message)${Reset}"
        }
    } else {
        Write-Host "${Yellow}Starship config not found in dotfiles repo, skipping...${Reset}"
    }

    # Symlink mise config
    $sourceMiseConfig = Join-Path $dotfilesDir "config\mise\config.toml"
    $targetMiseConfig = Join-Path $miseConfigDir 'config.toml'
    if (Test-Path -Path $sourceMiseConfig) {
        if (Test-Path -Path $targetMiseConfig) {
            $item = Get-Item $targetMiseConfig
            if ($item.LinkType -ne "SymbolicLink") {
                $backupPath = "$targetMiseConfig.bak"
                Copy-Item -Path $targetMiseConfig -Destination $backupPath -Force
                Write-Host "${Yellow}Backed up existing mise config to: $backupPath${Reset}"
            }
            Remove-Item -Path $targetMiseConfig -Force
        }
        try {
            New-Item -ItemType SymbolicLink -Path $targetMiseConfig -Target $sourceMiseConfig -Force | Out-Null
            Write-Host "${Green}Mise config symlinked.${Reset}"
        } catch {
            Write-Host "${Red}Failed to create symlink for mise config: $($_.Exception.Message)${Reset}"
        }
    } else {
        Write-Host "${Yellow}Mise config not found in dotfiles repo, skipping...${Reset}"
    }
}
Initialize-ConfigFiles

# Terminal-Icons module
function Install-TerminalIcons {
    if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
        Write-Host "${Yellow}Installing Terminal-Icons...${Reset}"
        Install-Module -Name Terminal-Icons -Repository PSGallery -Force
        Write-Host "${Green}Terminal-Icons installed.${Reset}"
    } else {
        Write-Host "${Cyan}Terminal-Icons already installed.${Reset}"
    }
}
Install-TerminalIcons

# Optional: AutoHotkey shortcuts
function Initialize-CustomShortcuts {
    $response = Read-UserInput -Prompt "${Cyan}Set up custom AutoHotkey shortcuts? (y/n) ${Reset}"
    if ($response.ToLower() -ne 'y') {
        Write-Host "${Yellow}Skipped.${Reset}"
        Write-Host ""
        return
    }

    # Check if shortcuts.ahk exists in dotfiles repository
    $sourceShortcutsPath = Join-Path $dotfilesDir "ahk\shortcuts.ahk"
    if (-not (Test-Path -Path $sourceShortcutsPath)) {
        Write-Host "${Yellow}shortcuts.ahk not found in dotfiles repository at: $sourceShortcutsPath${Reset}"
        Write-Host "${Yellow}Skipping AutoHotkey shortcuts setup.${Reset}"
        return
    }

    Write-Host "${Yellow}Installing AutoHotkey and setting up shortcuts...${Reset}"
    winget install -e --id AutoHotkey.AutoHotkey
    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutsPath = Join-Path $startupFolder 'shortcuts.ahk'

    try {
        # Copy shortcuts.ahk from dotfiles repository
        Copy-Item -Path $sourceShortcutsPath -Destination $shortcutsPath -Force
        Write-Host "${Green}Copied shortcuts.ahk from dotfiles repository.${Reset}"

        # Create desktop shortcut
        $desktopPath = [Environment]::GetFolderPath('Desktop')
        $shortcutPath = Join-Path $desktopPath 'Custom Shortcuts.lnk'
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = $shortcutsPath
        $Shortcut.WorkingDirectory = $startupFolder
        $Shortcut.Description = 'Custom Keyboard Shortcuts'
        $Shortcut.Save()
        if (Test-Path $shortcutsPath) { Start-Process $shortcutsPath }
        Write-Host "${Green}AutoHotkey shortcuts set up.${Reset}"
    } catch {
        Write-Host "${Red}Failed to set up shortcuts.`n$_${Reset}"
    }
}
Initialize-CustomShortcuts

# Neovim config
function Initialize-NeovimConfig {
    Write-Host "${Cyan}Setting up Neovim with LazyVim...${Reset}"
    $nvimConfigDir = "$env:LOCALAPPDATA\nvim"
    
    # Backup existing config if it exists
    if (Test-Path -Path $nvimConfigDir) {
        $backupDir = "$nvimConfigDir.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item -Path $nvimConfigDir -Destination $backupDir -Recurse -Force
        Write-Host "${Yellow}Backed up existing Neovim config to: $backupDir${Reset}"
        Remove-Item -Path $nvimConfigDir -Recurse -Force
    }
    
    # Create nvim config directory
    New-Item -ItemType Directory -Path $nvimConfigDir -Force | Out-Null
    
    # Clone LazyVim starter template
    try {
        Write-Host "${Cyan}Cloning LazyVim starter template...${Reset}"
        git clone https://github.com/LazyVim/starter $nvimConfigDir
        
        # Remove the .git folder so it can be added to user's own repo later
        $gitDir = Join-Path $nvimConfigDir '.git'
        if (Test-Path $gitDir) {
            Remove-Item -Path $gitDir -Recurse -Force
        }
        
        Write-Host "${Green}LazyVim installed successfully. Run 'nvim' to start, then ':LazyHealth' to verify setup.${Reset}"
    } catch {
        Write-Host "${Red}Failed to clone LazyVim starter template. Please check your internet connection and try again.${Reset}"
        Write-Host "${Red}Error: $($_.Exception.Message)${Reset}"
    }
}
Initialize-NeovimConfig

# Final notes (concise)
Write-Host ''
Write-Host "${Cyan}🎉 COMPLETE SELF-CONTAINED SETUP!${Reset}"
Write-Host "Everything uses your dotfiles repository - no external downloads needed!" -ForegroundColor White
Write-Host ''
Write-Host "${Cyan}Font setup:${Reset}"
Write-Host "JetBrains Mono Nerd Font is installed via Winget. Set it in Windows Terminal." -ForegroundColor White
Write-Host ''
Write-Host "${Cyan}Configuration:${Reset}"
Write-Host '• PowerShell profiles: ~/.local/share/dotfiles/powershell/Microsoft.PowerShell_profile.ps1' -ForegroundColor White
Write-Host '• Starship config: ~/.local/share/dotfiles/config/starship.toml' -ForegroundColor White
Write-Host '• Fastfetch config: ~/.local/share/dotfiles/config/fastfetch/windows.jsonc' -ForegroundColor White
Write-Host '• Mise config: ~/.local/share/dotfiles/config/mise/config.toml' -ForegroundColor White
Write-Host '• AutoHotkey shortcuts: ~/.local/share/dotfiles/ahk/shortcuts.ahk' -ForegroundColor White
Write-Host ''
Write-Host "${Cyan}✨ Key Benefits:${Reset}"
Write-Host '• All changes in your dotfiles repository are reflected immediately' -ForegroundColor White
Write-Host '• Version controlled configurations across all your machines' -ForegroundColor White
Write-Host '• No external dependencies - completely self-contained' -ForegroundColor White
Write-Host '• One script transforms any Windows machine into your perfect dev environment' -ForegroundColor White

Write-Host "${Green}`n🚀 Development environment setup complete!${Reset}"