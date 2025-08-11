# Minimal ANSI colors (PS7/Windows Terminal/TUI)
$esc   = [char]27
$Cyan  = "${esc}[36m"
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Blue  = "${esc}[34m"
$Reset = "${esc}[0m"

# Cross-version secure password reader
# Tries true no-echo console read first (no masking characters),
# then falls back to host/UI methods if a console is not available.
function Read-PasswordSecure {
    param(
        [Parameter(Mandatory=$true)][string]$PromptText
    )
    Write-Host $PromptText -NoNewline

    # In OSUTIL TUI mode, read from standard input without echo.
    # This avoids any host-provided masking like ****** entirely.
    if ($env:OSUTIL_TUI_MODE -eq '1') {
        try {
            $secure = New-Object System.Security.SecureString
            $stdin = [System.Console]::OpenStandardInput()
            $buffer = New-Object byte[] 1
            while ($true) {
                $read = $stdin.Read($buffer, 0, 1)
                if ($read -le 0) { break }
                $b = $buffer[0]
                if ($b -eq 13 -or $b -eq 10) { break } # CR or LF ends input
                if ($b -eq 8 -or $b -eq 127) { # Backspace/Delete
                    if ($secure.Length -gt 0) { $secure.RemoveAt($secure.Length - 1) }
                    continue
                }
                $secure.AppendChar([char]$b)
            }
            Write-Host ""
            return $secure
        } catch { }
    }

    # Primary path: read directly from the console without echo
    try {
        $secure = New-Object System.Security.SecureString
        while ($true) {
            $keyInfo = [System.Console]::ReadKey($true)
            if ($keyInfo.Key -eq [System.ConsoleKey]::Enter) { break }
            if ($keyInfo.Key -eq [System.ConsoleKey]::Backspace) {
                if ($secure.Length -gt 0) { $secure.RemoveAt($secure.Length - 1) }
            } else {
                $secure.AppendChar($keyInfo.KeyChar)
            }
        }
        Write-Host ""
        return $secure
    } catch {
        # Fall through to host-based methods
    }

    # Fallback 1: GUI credential prompt (no echo in console)
    try {
        $currentFullUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $cred = $Host.UI.PromptForCredential("Password Entry", "Enter password", $currentFullUser, "")
        if ($null -ne $cred) { return $cred.Password }
    } catch { }

    # Fallback 2: host UI secure input (may mask with asterisks depending on host)
    if ($Host -and $Host.UI -and ($Host.UI.PSObject.Methods.Name -contains 'ReadLineAsSecureString')) {
        return $Host.UI.ReadLineAsSecureString()
    }

    # Fallback 3: Read-Host secure input (may mask with asterisks depending on host)
    return Read-Host -AsSecureString
}

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
        $password1 = Read-PasswordSecure "${Yellow}Enter the new password: ${Reset}"
        $password2 = Read-PasswordSecure "${Yellow}Confirm the new password: ${Reset}"

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