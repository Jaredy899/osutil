# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Self-elevate the script if required
if (-not (Test-Administrator)) {
    Write-Output "Requesting administrative privileges..."
    Start-Process powershell.exe -Verb RunAs -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"")
    Exit
}

Write-Output "Script running with administrative privileges..."

# Function to change the password of the currently logged-in user
function Set-UserPassword {
    param (
        [SecureString]$password
    )
    $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split("\")[-1]
    Try {
        Write-Host "Attempting to change the password for $username..." -ForegroundColor Yellow
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        net user "$username" "$plainPassword" *>$null
        Write-Host "Password for ${username} account set successfully." -ForegroundColor Green
    } Catch {
        Write-Host "Failed to set password for ${username} account: $($_)" -ForegroundColor Red
    }
}

# Ask if the user wants to change the password
Write-Host "Do you want to change your password? " -ForegroundColor Cyan -NoNewline
Write-Host "(yes/y/enter for yes, no/n for no)" -ForegroundColor DarkGray
$changePassword = Read-Host

if ($changePassword -eq "yes" -or $changePassword -eq "y" -or [string]::IsNullOrEmpty($changePassword)) {
    $passwordsMatch = $false
    while (-not $passwordsMatch) {
        Write-Host "Enter the new password: " -ForegroundColor Yellow -NoNewline
        $password1 = Read-Host -AsSecureString
        Write-Host "Confirm the new password: " -ForegroundColor Yellow -NoNewline
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
            Write-Host "Password changed successfully." -ForegroundColor Green
        } else {
            Write-Host "Passwords do not match. Please try again or press Ctrl+C to cancel." -ForegroundColor Red
        }

        # Clear the plain text passwords from memory
        $plainPassword1 = $plainPassword2 = $null
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR1)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR2)
    }
} else {
    Write-Host "Password change was not performed." -ForegroundColor Blue
}

Write-Host "`nPassword setup complete!" -ForegroundColor Green 