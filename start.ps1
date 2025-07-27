#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

try {
    # Check if running on Windows
    if ($IsWindows -ne $true) {
        Write-Error "This utility is designed for Windows only"
        exit 1
    }

    function Get-Url {
        "https://github.com/Jaredy899/jaredmacutil/releases/latest/download/osutil.exe"
    }

    $tempFile = [System.IO.Path]::GetTempFileName()
    if (-not $?) {
        Write-Error "ERROR: Creating the temporary file"
        exit 1
    }

    $url = Get-Url
    Write-Host "Downloading osutil from $url"
    Invoke-WebRequest -Uri $url -OutFile $tempFile
    if (-not $?) {
        Write-Error "ERROR: Downloading osutil"
        Remove-Item -Path $tempFile -Force
        exit 1
    }

    # On Windows, we don't need to make the file executable in the same way as with chmod.
    # We also don't need to worry about the quarantine attribute.

    & $tempFile $args
    $exitCode = $LASTEXITCODE

    Remove-Item -Path $tempFile -Force
    if (-not $?) {
        Write-Error "ERROR: Deleting the temporary file"
    }

    exit $exitCode
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}