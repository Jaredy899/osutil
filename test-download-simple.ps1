# Simple download test
Write-Host "Testing download..."

$url = "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-windows.exe"
$tempFile = [System.IO.Path]::GetTempFileName()

Write-Host "URL: $url"
Write-Host "Temp file: $tempFile"

try {
    Write-Host "Starting download..."
    $response = Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing
    Write-Host "✓ Download successful!"
    Write-Host "File size: $((Get-Item $tempFile).Length) bytes"
} catch {
    Write-Host "✗ Download failed: $($_.Exception.Message)"
    Write-Host "Exception type: $($_.Exception.GetType().Name)"
}

# Clean up
if (Test-Path $tempFile) {
    Remove-Item $tempFile -Force
} 