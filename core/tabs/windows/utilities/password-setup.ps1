# Minimal ANSI colors (PS7/Windows Terminal/TUI)
$esc   = [char]27
$Cyan  = "${esc}[36m"
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Blue  = "${esc}[34m"
$Reset = "${esc}[0m"

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Self-elevate the script if required
if (-not (Test-Administrator)) {
    Write-Host "${Cyan}Requesting administrative privileges...${Reset}"
    Start-Process powershell.exe -Verb RunAs -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"")
    Exit
}

Write-Host "${Cyan}Script running with administrative privileges...${Reset}"

# Function to change the password of the currently logged-in user
function Set-UserPassword {
    param (
        [SecureString]$password
    )
    $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split("\")[-1]
    Try {
        Write-Host "${Yellow}Attempting to change the password for $username...${Reset}"
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        net user "$username" "$plainPassword" *>$null
        Write-Host "${Green}Password for ${username} account set successfully.${Reset}"
    } Catch {
        Write-Host "${Red}Failed to set password for ${username} account: $($_)${Reset}"
    }
}

# Ask if the user wants to change the password
Write-Host "${Cyan}Do you want to change your password? ${Reset}" -NoNewline
Write-Host "(yes/y/enter for yes, no/n for no)"
$changePassword = Read-Host

if ($changePassword -eq "yes" -or $changePassword -eq "y" -or [string]::IsNullOrEmpty($changePassword)) {
    $passwordsMatch = $false
    while (-not $passwordsMatch) {
        Write-Host "${Yellow}Enter the new password: ${Reset}" -NoNewline
        $password1 = Read-Host -AsSecureString
        Write-Host "${Yellow}Confirm the new password: ${Reset}" -NoNewline
        $password2 = Read-Host -AsSecureString

        # Convert SecureString to plain text for comparison
        $BSTR1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password1)
        $BSTR2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password2)
        $plainPassword1 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR1)
        $plainPassword2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR2)

        # Compare passwords
        if ($plainPassword1 -eq $plainPassword2) {
            $passwordsMatch = $true
            Set-UserPassword -password $password1
            Write-Host "${Green}Password changed successfully.${Reset}"
        } else {
            Write-Host "${Red}Passwords do not match. Please try again or press Ctrl+C to cancel.${Reset}"
        }

        # Clear the plain text passwords from memory
        $plainPassword1 = $plainPassword2 = $null
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR1)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR2)
    }
} else {
    Write-Host "${Blue}Password change was not performed.${Reset}"
}

Write-Host "${Green}`nPassword setup complete!${Reset}"