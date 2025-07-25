function Get-ProgramInstalled {
    param ([string]$programName)
    return (Get-Command $programName -ErrorAction SilentlyContinue) -ne $null
}

function Check-BrewInstalled {
    if (-not (Get-Command brew -ErrorAction SilentlyContinue)) {
        Write-Error "Brew is not installed. Please install it first."
        exit 1
    }
}

function Check-Admin {
    # Get the current user's identity
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()

    # Check if the user is an administrator
    (New-Object Security.Principal.WindowsPrincipal $currentUser).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Check-Env {
    # Check if running as an administrator
    if (-not (Check-Admin)) {
        Write-Warning "This script is not running with administrative privileges. Some commands may fail."
    }
}
