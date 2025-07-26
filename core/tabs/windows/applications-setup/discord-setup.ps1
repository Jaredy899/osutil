# Discord Setup Script for Windows
Write-Host "Installing Discord..." -ForegroundColor Green

# Check if Discord is already installed
$discordPath = "${env:LOCALAPPDATA}\Discord\Update.exe"
if (Test-Path $discordPath) {
    Write-Host "Discord is already installed. Launching..." -ForegroundColor Yellow
    Start-Process "discord://"
    exit 0
}

# Download Discord installer
$downloadUrl = "https://dl.discordapp.net/distro/app/stable/win/x86/1.0.9013/DiscordSetup.exe"
$installerPath = "$env:TEMP\DiscordSetup.exe"

Write-Host "Downloading Discord installer..." -ForegroundColor Blue
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath
} catch {
    Write-Host "Failed to download Discord installer: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Install Discord silently
Write-Host "Installing Discord..." -ForegroundColor Blue
try {
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
    Write-Host "Discord installed successfully!" -ForegroundColor Green
    
    # Clean up installer
    Remove-Item $installerPath -Force
    
    # Launch Discord
    Start-Process "discord://"
} catch {
    Write-Host "Failed to install Discord: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} 
