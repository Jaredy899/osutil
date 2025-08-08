# Download and extract Nord backgrounds to Documents\nord_backgrounds

[CmdletBinding()]
param(
    [switch]$Force
)

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
            Write-Host "Overwriting existing folder at '$backgroundsPath'..." -ForegroundColor Yellow
        }
        Remove-Item $backgroundsPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host 'Downloading Nord backgrounds...' -ForegroundColor Cyan
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

    Write-Host 'Extracting archive...' -ForegroundColor Cyan
    Expand-Archive -Path $zipPath -DestinationPath $extractRoot -Force

    # Find the extracted folder (usually nord-background-main)
    $extractedFolder = Get-ChildItem -Path $extractRoot -Directory | Select-Object -First 1
    if (-not $extractedFolder) { throw 'Failed to locate extracted folder.' }

    # Move to final location
    Move-Item -Path $extractedFolder.FullName -Destination $backgroundsPath -Force

    Write-Host "Nord backgrounds set up in: $backgroundsPath" -ForegroundColor Green
}
catch {
    Write-Host "Error setting up Nord backgrounds: $_" -ForegroundColor Red
}
finally {
    # Cleanup temp
    try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
} 