# Enable Sudo for Windows in Inline mode (normal)

function Test-Administrator {
    try {
        $current = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($current)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $false }
}

if (-not (Test-Administrator)) {
    Write-Host "Requesting administrative privileges to enable sudo..." -ForegroundColor Yellow
    $exe = (Get-Command pwsh -ErrorAction SilentlyContinue)?.Source
    if (-not $exe) { $exe = (Get-Command powershell -ErrorAction SilentlyContinue).Source }
    Start-Process $exe -Verb RunAs -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`""
    exit
}

Write-Host "Enabling Sudo for Windows in inline mode..." -ForegroundColor Cyan

# Prefer official config if sudo.exe is present
if (Get-Command sudo.exe -ErrorAction SilentlyContinue) {
    try {
        sudo config --enable normal
        Write-Host "✓ Sudo configured to run inline (normal)." -ForegroundColor Green
        exit 0
    } catch {
        Write-Host "! Failed to configure via sudo config. Falling back to registry..." -ForegroundColor Yellow
    }
}

# Fallback: set registry directly
try {
    New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion" -Name "Sudo" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Sudo" -Name "Enabled" -PropertyType DWord -Value 3 -Force | Out-Null
    Write-Host "✓ Sudo enabled in inline mode (registry set to 3)." -ForegroundColor Green
    Write-Host "If Terminal was open, you may need to restart it for changes to take effect." -ForegroundColor Yellow
    exit 0
} catch {
    Write-Host "✗ Failed to enable sudo. $_" -ForegroundColor Red
    exit 1
}


