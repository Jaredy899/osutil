#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

# Enable TLS 1.2 for PowerShell 5
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
    # Function to fetch the latest release tag from the GitHub API
    function Get-LatestRelease {
        try {
            $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/Jaredy899/osutil/releases" -TimeoutSec 30
            $latestRelease = $releases | Select-Object -First 1
            if (-not $latestRelease.tag_name) {
                Write-Host "Warning: Could not fetch release data from GitHub API"
                return $null
            }
            return $latestRelease.tag_name
        } catch {
            Write-Host "Warning: Could not fetch release data from GitHub API: $($_.Exception.Message)"
            return $null
        }
    }

    # Function to get the latest pre-release or fallback to latest release URL
    function Get-LatestPreReleaseUrl {
        $latestRelease = Get-LatestRelease
        if ($latestRelease) {
            $url = "https://github.com/Jaredy899/osutil/releases/download/$latestRelease/osutil.exe"
        }
        else {
            Write-Host 'Unable to determine latest pre-release version.'
            Write-Host "Using latest Full Release"
            $url = "https://github.com/Jaredy899/osutil/releases/latest/download/osutil.exe"
        }
        $url = Add-Arch -Url $url
        Write-Host "Using URL: $url"
        return $url
    }

    function Test-Error {
        param(
            [int]$exitCode,
            [string]$message
        )
        if ($exitCode -ne 0) {
            Write-Error "ERROR: $message"
            exit 1
        }
    }

    function Add-Arch {
        param(
            [string]$Url
        )
        # PowerShell doesn't have a direct equivalent of `uname -m`, but we can use other methods.
        # For simplicity, we'll assume x86_64 for now.
        $arch = "x86_64"
        if ($arch -ne "x86_64") {
            return "$Url-$arch"
        }
        return $Url
    }

    $url = Get-LatestPreReleaseUrl

    $tempFile = [System.IO.Path]::GetTempFileName()
    Test-Error $? "Creating the temporary file"

    Write-Host "Downloading osutil from $url"
    try {
        Invoke-WebRequest -Uri $url -OutFile $tempFile -TimeoutSec 30
        if (-not $?) {
            Test-Error 1 "Downloading osutil"
        }
    } catch {
        Write-Host "Network error: $($_.Exception.Message)"
        Write-Host "Please check your internet connection and try again."
        Test-Error 1 "Downloading osutil"
    }

    & $tempFile $args
    Test-Error $LASTEXITCODE "Executing osutil"

    Remove-Item -Path $tempFile -Force
    Test-Error $? "Deleting the temporary file"
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}