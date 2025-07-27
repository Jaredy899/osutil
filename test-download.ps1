# Test script to debug PowerShell download issues

Write-Host "=== PowerShell Download Test ===" -ForegroundColor Green

# Enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$url = "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-windows.exe"
$tempFile = [System.IO.Path]::GetTempFileName()

Write-Host "Testing download from: $url" -ForegroundColor Yellow
Write-Host "Temp file: $tempFile" -ForegroundColor Yellow

try {
    Write-Host "`nAttempting download with Invoke-WebRequest..." -ForegroundColor Cyan
    
    # Test 1: Basic download
    $response = Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing -TimeoutSec 30 -MaximumRedirection 5
    Write-Host "✓ Download successful!" -ForegroundColor Green
    Write-Host "Response Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "File size: $((Get-Item $tempFile).Length) bytes" -ForegroundColor Green
    
} catch {
    Write-Host "✗ Download failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Exception type: $($_.Exception.GetType().Name)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        Write-Host "HTTP Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        Write-Host "Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Red
    }
}

# Clean up
if (Test-Path $tempFile) {
    Remove-Item $tempFile -Force
    Write-Host "`nCleaned up temporary file" -ForegroundColor Green
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green 