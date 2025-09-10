#Requires -Version 5.1

param(
    [switch]$ForceNewWindow,
    [switch]$InSeparateWindow
)

$esc   = [char]27
$Cyan  = "${esc}[36m"
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Reset = "${esc}[0m"

$ErrorActionPreference = 'Stop'

$inTui = $env:OSUTIL_TUI_MODE -eq '1' -and -not $InSeparateWindow

# Handle console operations that may fail in non-interactive environments
function Write-ColoredOutput {
    param([string]$Message, [string]$Color = "")
    try {
        if ($Color) {
            Write-Host "$Color$Message${Reset}"
        } else {
            Write-Host $Message
        }
    } catch {
        # Fallback to plain text if colored output fails
        Write-Host $Message
    }
}

# Interactive WebApp Manager
if ($ForceNewWindow -or $inTui) {
    # In TUI or when forced: open a separate PowerShell window to ensure full interactivity
    $ps = $null
    $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($cmd) {
        $ps = $cmd.Source
    } else {
        $cmd = Get-Command powershell -ErrorAction SilentlyContinue
        if ($cmd) {
            $ps = $cmd.Source
        } else {
            $ps = 'powershell.exe'
        }
    }

    # Get the full path to the current script and launch with parameter to prevent infinite loop
    $scriptPath = $PSCommandPath
    Start-Process $ps -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-NoLogo','-File', $scriptPath, '-InSeparateWindow'
    exit 0
}
# If we reach here, we're not in TUI mode - run the script inline
try {
    Clear-Host
} catch {
    # Clear-Host may fail in non-interactive environments, ignore the error
}

Write-ColoredOutput "=== WebApp Manager ===" $Cyan
Write-ColoredOutput "What do you want to do?"
Write-ColoredOutput "  1) Install a new WebApp"
Write-ColoredOutput "  2) Remove an existing WebApp"

$choice = Read-Host "Choice (1 or 2)"

# Where we put WebApps
$startMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\WebApps"
if (!(Test-Path $startMenuDir)) { New-Item -ItemType Directory -Path $startMenuDir | Out-Null }

$profileBase = "$env:LOCALAPPDATA\WebApps"
if (!(Test-Path $profileBase)) { New-Item -ItemType Directory -Path $profileBase | Out-Null }

# Ensure ImageMagick present
function Install-ImageMagick {
    if (-not (Get-Command magick -ErrorAction SilentlyContinue)) {
        Write-ColoredOutput "⚠️ ImageMagick not found. Installing via winget..." $Yellow
        try {
            winget install --id=ImageMagick.ImageMagick -e --accept-source-agreements --accept-package-agreements
        }
        catch {
            Write-ColoredOutput "Failed to install ImageMagick: $($_.Exception.Message)" $Red
            throw
        }
    }
}

switch ($choice) {
    "1" {
        # INSTALL
        $AppName = Read-Host "App Name"
        $AppUrl  = Read-Host "App URL (e.g. https://example.com)"
        if (-not $AppUrl.StartsWith("http")) { $AppUrl = "https://$AppUrl" }
        Write-ColoredOutput "💡 You can browse icons at https://dashboardicons.com/" $Cyan
        $IconUrl = Read-Host "Icon URL (PNG)"

        # Profile dir
        try {
            $domain = ([Uri]$AppUrl).Host.Replace(".", "_")
        }
        catch {
            Write-ColoredOutput "Invalid URL format: $AppUrl" $Red
            exit 1
        }
        $profileDir = Join-Path $profileBase $domain

        # Detect default browser exe
        try {
            $assoc    = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice"
            $progId   = $assoc.ProgId
            $cmdPath  = "Registry::HKEY_CLASSES_ROOT\$progId\shell\open\command"
            $command  = (Get-ItemProperty $cmdPath)."(default)"
            if ($command -match '"([^"]+\.exe)"') {
                $browser = $matches[1]
            } else {
                Write-Error "Could not detect default browser executable."
                exit 1
            }
        }
        catch {
            Write-ColoredOutput "Failed to detect default browser: $($_.Exception.Message)" $Red
            exit 1
        }

        # Get + Convert icon
        $tmpPng   = Join-Path $env:TEMP ($AppName + ".png")
        $iconPath = Join-Path $startMenuDir ($AppName + ".ico")

        try {
            Write-ColoredOutput "Downloading icon..." $Cyan
            Invoke-WebRequest -Uri $IconUrl -OutFile $tmpPng -UseBasicParsing
            Install-ImageMagick
            Write-ColoredOutput "Converting icon..." $Cyan
            & magick $tmpPng -define icon:auto-resize=256,128,64,48,32,16 $iconPath
            Write-ColoredOutput "Icon converted successfully." $Green
        } catch {
            Write-ColoredOutput "Icon conversion failed — using default browser icon." $Yellow
            $iconPath = "$browser,0"
        }

        # Build arguments (isolation mode by default)
        $browserArgs = "--app=$AppUrl --profile-directory=Default --start-maximized"

        # Shortcut
        $shortcutPath = Join-Path $startMenuDir ($AppName + ".lnk")
        try {
            Write-ColoredOutput "Creating shortcut..." $Cyan
            $WScriptShell = New-Object -ComObject WScript.Shell
            $shortcut = $WScriptShell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath  = $browser
            $shortcut.Arguments   = $browserArgs
            $shortcut.WorkingDirectory = Split-Path $browser
            $shortcut.IconLocation = $iconPath
            $shortcut.Save()
            Write-ColoredOutput "`n✅ $AppName installed! It's now in Start Menu → WebApps." $Green
        }
        catch {
            Write-ColoredOutput "Failed to create shortcut: $($_.Exception.Message)" $Red
            exit 1
        }
    }

    "2" {
        $apps = Get-ChildItem -Path $startMenuDir -Filter *.lnk
        if (-not $apps) {
            Write-ColoredOutput "No WebApps found to remove." $Yellow
            exit 0
        }

        Write-ColoredOutput "`nInstalled WebApps:" $Cyan
        for ($i = 0; $i -lt $apps.Count; $i++) {
            $displayName = [System.IO.Path]::GetFileNameWithoutExtension($apps[$i].Name)
            Write-Host "  [$i] $displayName"
        }

        $selection = Read-Host "Which number to remove?"
        if ($selection -match '^\d+$' -and $selection -lt $apps.Count) {
            $appFile = $apps[$selection]
            $appName = [System.IO.Path]::GetFileNameWithoutExtension($appFile.Name)

            # Real paths
            $shortcutPath = $appFile.FullName
            $iconPath     = [System.IO.Path]::ChangeExtension($shortcutPath, ".ico")
            $profileDir   = Join-Path $profileBase $appName

            try {
                if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force }
                if (Test-Path $iconPath)     { Remove-Item $iconPath -Force }
                if (Test-Path $profileDir)   { Remove-Item $profileDir -Recurse -Force }

                Write-ColoredOutput "`n🗑️ Removed $appName." $Green
            }
            catch {
                Write-ColoredOutput "Failed to remove $appName" $Red
                Write-ColoredOutput "Error: $($_.Exception.Message)" $Red
                exit 1
            }
        } else {
            Write-ColoredOutput "Invalid selection." $Red
        }
    }

    default { Write-ColoredOutput "Invalid choice. Exiting." $Red }
}
