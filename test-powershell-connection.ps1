# PowerShell Connection Test Script
# This script helps diagnose connectivity issues with PowerShell

Write-Host "=== PowerShell Connection Diagnostic ===" -ForegroundColor Green
Write-Host ""

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion
Write-Host "PowerShell Version: $psVersion" -ForegroundColor Yellow

# Check execution policy
$executionPolicy = Get-ExecutionPolicy
Write-Host "Execution Policy: $executionPolicy" -ForegroundColor Yellow

# Check TLS version
$tlsVersion = [Net.ServicePointManager]::SecurityProtocol
Write-Host "Current TLS Version: $tlsVersion" -ForegroundColor Yellow

# Enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Host "TLS 1.2 enabled" -ForegroundColor Green

# Test basic internet connectivity
Write-Host "`nTesting basic internet connectivity..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "https://www.google.com" -UseBasicParsing -TimeoutSec 10
    Write-Host "✓ Basic internet connectivity: OK" -ForegroundColor Green
} catch {
    Write-Host "✗ Basic internet connectivity: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test GitHub API connectivity
Write-Host "`nTesting GitHub API connectivity..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "https://api.github.com" -TimeoutSec 10
    Write-Host "✓ GitHub API connectivity: OK" -ForegroundColor Green
} catch {
    Write-Host "✗ GitHub API connectivity: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test specific repository access
Write-Host "`nTesting repository access..." -ForegroundColor Cyan
$repoUrl = "https://github.com/Jaredy899/osutil"
try {
    $response = Invoke-WebRequest -Uri $repoUrl -UseBasicParsing -TimeoutSec 10
    Write-Host "✓ Repository access: OK" -ForegroundColor Green
} catch {
    Write-Host "✗ Repository access: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test releases API
Write-Host "`nTesting releases API..." -ForegroundColor Cyan
$releasesUrl = "https://api.github.com/repos/Jaredy899/osutil/releases"
try {
    $response = Invoke-RestMethod -Uri $releasesUrl -TimeoutSec 10
    Write-Host "✓ Releases API: OK" -ForegroundColor Green
    Write-Host "Latest release: $($response[0].tag_name)" -ForegroundColor Green
} catch {
    Write-Host "✗ Releases API: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test download URL
Write-Host "`nTesting download URL..." -ForegroundColor Cyan
$downloadUrl = "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-windows.exe"
try {
    $response = Invoke-WebRequest -Uri $downloadUrl -UseBasicParsing -TimeoutSec 10 -Method Head
    Write-Host "✓ Download URL: OK" -ForegroundColor Green
    Write-Host "Content Length: $($response.Headers.'Content-Length') bytes" -ForegroundColor Green
} catch {
    Write-Host "✗ Download URL: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Diagnostic Complete ===" -ForegroundColor Green 