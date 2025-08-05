# Define the GitHub base URL for your setup scripts
$githubBaseUrl = "https://raw.githubusercontent.com/Jaredy899/win/main/my_powershell"

# Corrected specific URLs for each setup script
$appsScriptUrl = "$githubBaseUrl/apps_install.ps1"
$configJsoncUrl = "$githubBaseUrl/config.jsonc"
$starshipTomlUrl = "$githubBaseUrl/starship.toml"
$githubProfileUrl = "$githubBaseUrl/Microsoft.PowerShell_profile.ps1"
$fontScriptUrl = "$githubBaseUrl/install_nerd_font.ps1"
$wingetScriptUrl = "$githubBaseUrl/install_winget.ps1"

# Add new URL for shortcuts.ahk
$shortcutsAhkUrl = "$githubBaseUrl/shortcuts.ahk"

# Local paths where the scripts will be temporarily downloaded
$appsScriptPath = "$env:TEMP\apps_install.ps1"
$fontScriptPath = "$env:TEMP\install_nerd_font.ps1"
$wingetScriptPath = "$env:TEMP\install_winget.ps1"

# Function to download and run a script using Start-BitsTransfer
function Invoke-DownloadAndRunScript {
    param (
        [string]$url,
        [string]$localPath
    )

    Write-Host "Downloading script from " -ForegroundColor Yellow -NoNewline
    Write-Host "$url" -ForegroundColor Blue -NoNewline
    Write-Host "..." -ForegroundColor Yellow
    try {
        Start-BitsTransfer -Source $url -Destination $localPath -ErrorAction Stop
        Write-Host "Running script " -ForegroundColor Yellow -NoNewline
        Write-Host "$localPath" -ForegroundColor Blue -NoNewline
        Write-Host "..." -ForegroundColor Yellow
        & $localPath
    }
    catch {
        Write-Host "Failed to download or run the script from $url. Error: $_" -ForegroundColor Red
    }
}

# Ensure Winget is installed or updated
Write-Host "Checking Winget installation..." -ForegroundColor Cyan
Invoke-DownloadAndRunScript -url $wingetScriptUrl -localPath $wingetScriptPath

# Always run the applications installation script
Write-Host "Running the applications installation script..." -ForegroundColor Cyan
Invoke-DownloadAndRunScript -url $appsScriptUrl -localPath $appsScriptPath

# Run the font installation script
Write-Host "Running the Nerd Font installation script..." -ForegroundColor Cyan
Invoke-DownloadAndRunScript -url $fontScriptUrl -localPath $fontScriptPath

# URLs for GitHub profile configuration
$githubProfileUrl = "https://raw.githubusercontent.com/Jaredy899/win/main/my_powershell/Microsoft.PowerShell_profile.ps1"

# Function to initialize PowerShell profile
function Initialize-Profile {
    param (
        [string]$profilePath,
        [string]$profileUrl
    )

    Write-Host "Setting up PowerShell profile at " -ForegroundColor Yellow -NoNewline
    Write-Host "$profilePath" -ForegroundColor Blue -NoNewline
    Write-Host "..." -ForegroundColor Yellow

    $profileDir = Split-Path $profilePath
    if (-not (Test-Path -Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force
    }

    if (-not [string]::IsNullOrEmpty($profileUrl)) {
        Start-BitsTransfer -Source $profileUrl -Destination $profilePath -ErrorAction Stop
        Write-Host "PowerShell profile has been set up successfully!" -ForegroundColor Green
    } else {
        Write-Host "GitHub profile URL is not set or is empty. Cannot set up the PowerShell profile." -ForegroundColor Red
    }
}

# Paths for PowerShell 5 and PowerShell 7 profiles
$ps5ProfilePath = "$env:UserProfile\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$ps7ProfilePath = "$env:UserProfile\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

# Initialize PowerShell 5 profile
Initialize-Profile -profilePath $ps5ProfilePath -profileUrl $githubProfileUrl

# Initialize PowerShell 7 profile
Initialize-Profile -profilePath $ps7ProfilePath -profileUrl $githubProfileUrl

# Function to initialize configuration files
function Initialize-ConfigFiles {
    Write-Host "Setting up configuration files..." -ForegroundColor Cyan

    $userConfigDir = "$env:UserProfile\.config"
    $fastfetchConfigDir = "$userConfigDir\fastfetch"

    if (-not (Test-Path -Path $fastfetchConfigDir)) {
        New-Item -ItemType Directory -Path $fastfetchConfigDir -Force
    }

    $localConfigJsoncPath = "$fastfetchConfigDir\config.jsonc"
    Start-BitsTransfer -Source $configJsoncUrl -Destination $localConfigJsoncPath -ErrorAction Stop
    Write-Host "fastfetch config.jsonc has been set up successfully!" -ForegroundColor Green

    $localStarshipTomlPath = "$userConfigDir\starship.toml"
    Start-BitsTransfer -Source $starshipTomlUrl -Destination $localStarshipTomlPath -ErrorAction Stop
    Write-Host "starship.toml has been set up successfully!" -ForegroundColor Green
}

# Run the Initialize-ConfigFiles function
Initialize-ConfigFiles

# Function to install Terminal-Icons
function Install-TerminalIcons {
    if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
        Write-Host "Installing Terminal-Icons module..." -ForegroundColor Yellow
        Install-Module -Name Terminal-Icons -Repository PSGallery -Force
        Write-Host "Terminal-Icons module installed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Terminal-Icons module is already installed." -ForegroundColor Blue
    }
}

# Run the Install-TerminalIcons function
Install-TerminalIcons

# Function to setup AutoHotkey and shortcuts
function Initialize-CustomShortcuts {
    Write-Host "Would you like to set up custom keyboard shortcuts using AutoHotkey? (y/n) " -ForegroundColor Cyan -NoNewline
    $response = Read-Host
    
    if ($response.ToLower() -eq 'y') {
        Write-Host "Installing AutoHotkey and setting up shortcuts..." -ForegroundColor Yellow
        
        winget install -e --id AutoHotkey.AutoHotkey
        
        $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
        $shortcutsPath = "$startupFolder\shortcuts.ahk"
        
        try {
            Start-BitsTransfer -Source $shortcutsAhkUrl -Destination $shortcutsPath -ErrorAction Stop
            Write-Host "AutoHotkey shortcuts have been set up successfully!" -ForegroundColor Green
            
            # Create desktop shortcut
            $desktopPath = [Environment]::GetFolderPath("Desktop")
            $shortcutPath = "$desktopPath\Custom Shortcuts.lnk"
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($shortcutPath)
            $Shortcut.TargetPath = $shortcutsPath
            $Shortcut.WorkingDirectory = $startupFolder
            $Shortcut.Description = "Custom Keyboard Shortcuts"
            $Shortcut.Save()
            Write-Host "Desktop shortcut created successfully!" -ForegroundColor Green
            
            if (Test-Path $shortcutsPath) {
                Start-Process $shortcutsPath
                Write-Host "Custom shortcuts are now active!" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Failed to download or setup shortcuts. Error: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Skipping custom shortcuts setup." -ForegroundColor Blue
    }
}

# Run the Initialize-CustomShortcuts function
Initialize-CustomShortcuts

# Function to setup Neovim configuration files
function Initialize-NeovimConfig {
    Write-Host "Setting up Neovim configuration..." -ForegroundColor Cyan
    
    $nvimConfigDir = "$env:LOCALAPPDATA\nvim"
    
    # Create nvim directory if it doesn't exist
    if (-not (Test-Path -Path $nvimConfigDir)) {
        New-Item -ItemType Directory -Path $nvimConfigDir -Force
        Write-Host "Created Neovim configuration directory: $nvimConfigDir" -ForegroundColor Green
    } else {
        Write-Host "Neovim configuration directory already exists: $nvimConfigDir" -ForegroundColor Blue
        
        # Backup existing config
        $backupDir = "$nvimConfigDir.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Host "Creating backup of existing Neovim configuration at: $backupDir" -ForegroundColor Yellow
        Copy-Item -Path $nvimConfigDir -Destination $backupDir -Recurse -Force
        
        # Clear existing directory
        Remove-Item -Path "$nvimConfigDir\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Create a temporary directory to download the files
    $tempDir = "$env:TEMP\nvim_download"
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Download the nvim.zip file from GitHub
    $zipUrl = "https://github.com/Jaredy899/win/archive/refs/heads/main.zip"
    $zipPath = "$tempDir\repo.zip"
    
    Write-Host "Downloading Neovim configuration files from GitHub..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
        
        # Extract the zip file
        Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
        
        # Copy the nvim folder to the destination
        $extractedNvimPath = "$tempDir\win-main\my_powershell\nvim"
        if (Test-Path $extractedNvimPath) {
            Copy-Item -Path "$extractedNvimPath\*" -Destination $nvimConfigDir -Recurse -Force
            Write-Host "Neovim configuration installed successfully!" -ForegroundColor Green
        } else {
            Write-Host "Could not find nvim folder in the downloaded repository." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error downloading or extracting files: $_" -ForegroundColor Red
    }
    
    # Clean up temporary files
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}

# Run the Initialize-NeovimConfig function
Initialize-NeovimConfig

# Instructions for Manual Font Configuration
Write-Host ""
Write-Host "=== Manual Font Configuration ===" -ForegroundColor Cyan
Write-Host "To set the font for Windows Terminal to 'Fira Code Nerd Font', please follow these steps:" -ForegroundColor Yellow
Write-Host "1. Open Windows Terminal." -ForegroundColor White
Write-Host "2. Go to Settings." -ForegroundColor White
Write-Host "3. Select the 'Windows PowerShell' profile." -ForegroundColor White
Write-Host "4. Under 'Appearance', set the 'Font face' to 'Fira Code Nerd Font'." -ForegroundColor White
Write-Host "5. Save and close the settings." -ForegroundColor White
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

# Final notes
Write-Host "Note: This profile will update every time you run the script." -ForegroundColor Yellow
Write-Host "If you wish to keep your own aliases or customizations, create a separate profile.ps1 file." -ForegroundColor Yellow
Write-Host "You can use nano to create or edit this file by running the following command:" -ForegroundColor Cyan
Write-Host "`nStart-Process 'nano' -ArgumentList '$HOME\Documents\PowerShell\profile.ps1'`n" -ForegroundColor White
Write-Host "After adding your custom aliases or functions, save the file and restart your shell to apply the changes." -ForegroundColor Magenta

Write-Host "`nDevelopment setup complete!" -ForegroundColor Green 