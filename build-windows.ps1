# Windows build script
# This script builds the project for Windows

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Building osutil for Windows..." -ForegroundColor Green

# Check if we're on Windows
if ($env:OS -ne "Windows_NT") {
    Write-Host "Error: This script must be run on Windows" -ForegroundColor Red
    exit 1
}

# Check if we're in the right directory
if (-not (Test-Path "Cargo.toml")) {
    Write-Host "Error: Cargo.toml not found. Please run this script from the project root." -ForegroundColor Red
    exit 1
}

# Function to check if command exists
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Function to install Rust
function Install-Rust {
    if (-not (Test-Command "rustc")) {
        Write-Host "Rust not found. Installing Rust..." -ForegroundColor Yellow
        try {
            # Download and run rustup-init
            $rustupUrl = "https://win.rustup.rs/x86_64"
            $rustupPath = "$env:TEMP\rustup-init.exe"
            
            Write-Host "Downloading Rust installer..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $rustupUrl -OutFile $rustupPath -UseBasicParsing
            
            Write-Host "Installing Rust..." -ForegroundColor Yellow
            Start-Process -FilePath $rustupPath -ArgumentList "-y" -Wait -NoNewWindow
            
            # Refresh environment variables
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
            
            Write-Host "Rust installed successfully!" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to install Rust automatically. Please install manually from https://rustup.rs/" -ForegroundColor Red
            exit 1
        }
        finally {
            if (Test-Path $rustupPath) {
                Remove-Item $rustupPath -Force
            }
        }
    } else {
        Write-Host "Rust is already installed: $(rustc --version)" -ForegroundColor Green
    }
}

# Function to update Rust
function Update-Rust {
    Write-Host "Updating Rust toolchain..." -ForegroundColor Yellow
    try {
        rustup update
        Write-Host "Rust updated successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to update Rust. Continuing with current version..." -ForegroundColor Yellow
    }
}

# Function to install Visual Studio Build Tools
function Install-BuildTools {
    if (-not (Test-Command "cl")) {
        Write-Host "Visual Studio Build Tools not found. Installing..." -ForegroundColor Yellow
        try {
            # Check if winget is available
            if (Test-Command "winget") {
                Write-Host "Installing Visual Studio Build Tools via winget..." -ForegroundColor Yellow
                winget install Microsoft.VisualStudio.2022.BuildTools --silent --accept-source-agreements --accept-package-agreements
            } else {
                Write-Host "winget not available. Please install Visual Studio Build Tools manually:" -ForegroundColor Yellow
                Write-Host "https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022" -ForegroundColor Cyan
                Write-Host "Make sure to include 'MSVC v143 - VS 2022 C++ x64/x86 build tools'" -ForegroundColor Cyan
                $response = Read-Host "Press Enter after installing Build Tools, or 'q' to quit"
                if ($response -eq 'q') {
                    exit 1
                }
            }
        }
        catch {
            Write-Host "Failed to install Build Tools automatically. Please install manually:" -ForegroundColor Red
            Write-Host "https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022" -ForegroundColor Cyan
            exit 1
        }
    } else {
        Write-Host "Visual Studio Build Tools are already installed" -ForegroundColor Green
    }
}

# Check and install prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Cyan

# Install Rust
Install-Rust
Update-Rust

# Install Build Tools
Install-BuildTools

# Create build directory
$BUILD_DIR = "build"
if (-not (Test-Path $BUILD_DIR)) {
    New-Item -ItemType Directory -Path $BUILD_DIR | Out-Null
}

# Detect architecture
$ARCH = $env:PROCESSOR_ARCHITECTURE
Write-Host "Detected architecture: $ARCH" -ForegroundColor Yellow

# Build for Windows
Write-Host "Building for Windows $ARCH..." -ForegroundColor Yellow
cargo build --release --all-features

# Copy binary to build directory
$BINARY_PATH = "target\release\osutil.exe"
if (Test-Path $BINARY_PATH) {
    Copy-Item $BINARY_PATH $BUILD_DIR\
    Write-Host "✓ Built osutil.exe for Windows $ARCH" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to build for Windows $ARCH" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Build completed! Binary in $BUILD_DIR\:" -ForegroundColor Green
Get-ChildItem $BUILD_DIR | Format-Table Name, Length, LastWriteTime

Write-Host ""
Write-Host "Build Summary:" -ForegroundColor Cyan
Write-Host "- Windows $ARCH`: $BUILD_DIR\osutil.exe" -ForegroundColor White
Write-Host ""
Write-Host "To install system-wide, copy the binary to a directory in your PATH" -ForegroundColor Yellow
Write-Host "For example: Copy-Item '$BUILD_DIR\osutil.exe' 'C:\Windows\System32\'" -ForegroundColor Cyan 