#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

# Enable TLS 1.2 for PowerShell 5
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
    # Check if running on Windows
    if ($IsWindows -ne $true) {
        Write-Error "This utility is designed for Windows only"
        exit 1
    }

    function Get-Url {
        "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-windows.exe"
    }

    $tempFile = [System.IO.Path]::GetTempFileName()
    $exeFile = [System.IO.Path]::ChangeExtension($tempFile, ".exe")
    if (-not $?) {
        Write-Error "ERROR: Creating the temporary file"
        exit 1
    }

    $url = Get-Url
    Write-Host "Downloading osutil from $url"
    try {
        $response = Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing -TimeoutSec 30 -MaximumRedirection 5
        Write-Host "✓ Download completed successfully"
    } catch {
        Write-Error "ERROR: Downloading osutil - $($_.Exception.Message)"
        Remove-Item -Path $tempFile -Force
        exit 1
    }

    # Rename to .exe extension and unblock
    Write-Host "Preparing executable..."
    Move-Item -Path $tempFile -Destination $exeFile -Force
    Unblock-File -Path $exeFile

    & $exeFile $args
    $exitCode = $LASTEXITCODE

    Remove-Item -Path $exeFile -Force
    if (-not $?) {
        Write-Error "ERROR: Deleting the temporary file"
    }

    exit $exitCode
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}