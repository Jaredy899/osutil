# Download and extract Nord backgrounds to Documents

[CmdletBinding()]
param(
    [switch]$Force
)

$esc   = [char]27
$Cyan  = "${esc}[36m"
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Reset = "${esc}[0m"

$ErrorActionPreference = 'Stop'

# Ensure TLS 1.2 for GitHub
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$documentsPath = [Environment]::GetFolderPath('MyDocuments')
$backgroundsPath = Join-Path $documentsPath 'nord_backgrounds'
$tempDir = Join-Path $env:TEMP ('nord_bg_' + [guid]::NewGuid().ToString('n'))
$zipPath = Join-Path $tempDir 'nord_backgrounds.zip'
$extractRoot = Join-Path $tempDir 'extract'
$url = 'https://github.com/ChrisTitusTech/nord-background/archive/refs/heads/main.zip'

# Auto-force in TUI to avoid Read-Host prompts drawing outside the TUI
$inTui = $env:OSUTIL_TUI_MODE -eq '1'
if ($inTui) { $Force = $true }

New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null

try {
    if (Test-Path $backgroundsPath) {
        if (-not $Force) {
            $ans = Read-Host "Nord backgrounds folder exists at '$backgroundsPath'. Overwrite? (y/n)"
            if ($ans -ne 'y') { Write-Host 'Skipping Nord backgrounds download.'; return }
        } else {
            Write-Host "${Yellow}Overwriting existing folder at '$backgroundsPath'...${Reset}"
        }
        Remove-Item $backgroundsPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host "${Cyan}Downloading Nord backgrounds...${Reset}"
    try {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
    } catch {
        # Fallback to BITS if available
        if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
            Start-BitsTransfer -Source $url -Destination $zipPath
        } else {
            throw $_
        }
    }

    Write-Host "${Cyan}Extracting archive...${Reset}"
    Expand-Archive -Path $zipPath -DestinationPath $extractRoot -Force

    # Find the extracted folder (usually nord-background-main)
    $extractedFolder = Get-ChildItem -Path $extractRoot -Directory | Select-Object -First 1
    if (-not $extractedFolder) { throw 'Failed to locate extracted folder.' }

    # Move to final location
    Move-Item -Path $extractedFolder.FullName -Destination $backgroundsPath -Force

    Write-Host "${Green}Nord backgrounds set up in: $backgroundsPath${Reset}"
}
catch {
    Write-Host "${Red}Error setting up Nord backgrounds: $_${Reset}"
}
finally {
    # Cleanup temp
    try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
} 