#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

try {
    # Function to fetch the latest release tag from the GitHub API
    function Get-LatestRelease {
        $latestRelease = (Invoke-RestMethod -Uri "https://api.github.com/repos/Jaredy899/macutil/releases").tag_name | Select-Object -First 1
        if (-not $latestRelease) {
            Write-Error "Error fetching release data"
            return $null
        }
        return $latestRelease
    }

    # Function to redirect to the latest pre-release version
    function Redirect-ToLatestPreRelease {
        $latestRelease = Get-LatestRelease
        if ($latestRelease) {
            $url = "https://github.com/Jaredy899/macutil/releases/download/$latestRelease/macutil.exe"
        }
        else {
            Write-Host 'Unable to determine latest pre-release version.'
            Write-Host "Using latest Full Release"
            $url = "https://github.com/Jaredy899/macutil/releases/latest/download/macutil.exe"
        }
        Add-Arch
        Write-Host "Using URL: $url"
    }

    function Check-Error {
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
        # PowerShell doesn't have a direct equivalent of `uname -m`, but we can use other methods.
        # For simplicity, we'll assume x86_64 for now.
        # A more robust solution might involve checking environment variables or using .NET APIs.
        $arch = "x86_64"
        if ($arch -ne "x86_64") {
            $url = "$url-$arch"
        }
    }

    Redirect-ToLatestPreRelease

    $tempFile = [System.IO.Path]::GetTempFileName()
    Check-Error $? "Creating the temporary file"

    Write-Host "Downloading macutil from $url"
    Invoke-WebRequest -Uri $url -OutFile $tempFile
    Check-Error $? "Downloading macutil"

    & $tempFile $args
    Check-Error $LASTEXITCODE "Executing macutil"

    Remove-Item -Path $tempFile -Force
    Check-Error $? "Deleting the temporary file"
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}