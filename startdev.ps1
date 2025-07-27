#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

try {
    # Function to fetch the latest release tag from the GitHub API
    function Get-LatestRelease {
        $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/Jaredy899/jaredmacutil/releases"
        $latestRelease = $releases | Select-Object -First 1
        if (-not $latestRelease.tag_name) {
            Write-Error "Error fetching release data"
            return $null
        }
        return $latestRelease.tag_name
    }

    # Function to get the latest pre-release or fallback to latest release URL
    function Get-LatestPreReleaseUrl {
        $latestRelease = Get-LatestRelease
        if ($latestRelease) {
            $url = "https://github.com/Jaredy899/jaredmacutil/releases/download/$latestRelease/osutil.exe"
        }
        else {
            Write-Host 'Unable to determine latest pre-release version.'
            Write-Host "Using latest Full Release"
            $url = "https://github.com/Jaredy899/jaredmacutil/releases/latest/download/osutil.exe"
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
    Invoke-WebRequest -Uri $url -OutFile $tempFile
    Test-Error $? "Downloading osutil"

    & $tempFile $args
    Test-Error $LASTEXITCODE "Executing osutil"

    Remove-Item -Path $tempFile -Force
    Test-Error $? "Deleting the temporary file"
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}