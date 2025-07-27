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

function Set-RemoteDesktop {
    Try {
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Value 0 -PropertyType DWORD -Force *>$null
        Write-Host "Remote Desktop enabled." -ForegroundColor Green
    } Catch {
        Write-Host "Failed to enable Remote Desktop: $($_)" -ForegroundColor Red
    }
}

function Enable-FirewallRule {
    param (
        [string]$ruleGroup,
        [string]$ruleName,
        [string]$protocol = "",
        [string]$localPort = ""
    )
    Try {
        if ($protocol -and $localPort) {
            netsh advfirewall firewall add rule name="$ruleName" protocol="$protocol" dir=in action=allow *>$null
        } else {
            netsh advfirewall firewall set rule group="$ruleGroup" new enable=Yes *>$null
        }
        Write-Host "${ruleName} rule enabled." -ForegroundColor Green
    } Catch {
        Write-Host "Failed to enable ${ruleName} rule: $($_)" -ForegroundColor Red
    }
}

function Install-WindowsCapability {
    param (
        [string]$capabilityName
    )
    if ((Get-WindowsCapability -Online | Where-Object Name -like "$capabilityName*").State -ne 'Installed') {
        Try {
            Add-WindowsCapability -Online -Name $capabilityName *>$null
            Write-Host "${capabilityName} installed successfully." -ForegroundColor Green
        } Catch {
            Write-Host "Failed to install ${capabilityName}: $($_)" -ForegroundColor Red
        }
    } else {
        Write-Host "${capabilityName} is already installed." -ForegroundColor Blue
    }
}

function Set-SSHConfiguration {
    Try {
        Start-Service sshd *>$null
        Set-Service -Name sshd -StartupType 'Automatic' *>$null
        Write-Host "SSH service started and set to start automatically." -ForegroundColor Green
    } Catch {
        Write-Host "Failed to configure SSH service: $($_)" -ForegroundColor Red
    }

    Try {
        $firewallRuleExists = Get-NetFirewallRule -Name 'sshd' -ErrorAction SilentlyContinue
        if ($null -eq $firewallRuleExists) {
            Try {
                New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 *>$null
                Write-Host "Firewall rule for OpenSSH Server (sshd) created successfully." -ForegroundColor Green
            } Catch {
                Write-Host "Failed to create firewall rule for OpenSSH Server (sshd): $($_)" -ForegroundColor Red
            }
        } else {
            Write-Host "Firewall rule for OpenSSH Server (sshd) already exists." -ForegroundColor Blue
        }
    } Catch {
        Write-Host "Failed to check for existing firewall rule: $($_)" -ForegroundColor Red
    }

    Try {
        New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Program Files\PowerShell\7\pwsh.exe" -PropertyType String -Force *>$null
        Write-Host "Default shell for OpenSSH set to PowerShell 7." -ForegroundColor Green
    } Catch {
        Write-Host "Failed to set default shell for OpenSSH: $($_)" -ForegroundColor Red
    }
}

function Set-TimeSettings {
    Try {
        # Attempt to automatically detect timezone
        Try {
            # Try multiple geolocation services
            $timezone = $null
            
            # Try ipapi.co first
            Try {
                $timezone = (Invoke-RestMethod -Uri "https://ipapi.co/timezone" -Method Get -TimeoutSec 5).Trim()
            } Catch {
                Write-Output "ipapi.co detection failed, trying alternative service..."
            }
            
            if ($timezone) {
                Write-Host "Detected timezone: $timezone" -ForegroundColor Yellow
                
                # Simplified mapping for common US timezones
                $tzMapping = @{
                    'America/New_York' = 'Eastern Standard Time'
                    'America/Chicago' = 'Central Standard Time'
                    'America/Denver' = 'Mountain Standard Time'
                    'America/Los_Angeles' = 'Pacific Standard Time'
                    'America/Anchorage' = 'Alaskan Standard Time'
                    'Pacific/Honolulu' = 'Hawaiian Standard Time'
                }

                if ($tzMapping.ContainsKey($timezone)) {
                    $windowsTimezone = $tzMapping[$timezone]
                    tzutil /s $windowsTimezone *>$null
                    Write-Host "Time zone automatically set to $windowsTimezone" -ForegroundColor Green
                } else {
                    throw "Could not map timezone"
                }
            } else {
                throw "Could not detect timezone"
            }
        } Catch {
            Write-Host "Automatic timezone detection failed. Falling back to manual selection..." -ForegroundColor Yellow
            # Display options for time zones
            Write-Host "Select a time zone from the options below:" -ForegroundColor Cyan
            $timeZones = @(
                "Eastern Standard Time",
                "Central Standard Time",
                "Mountain Standard Time",
                "Pacific Standard Time",
                "Greenwich Standard Time",
                "UTC",
                "Hawaiian Standard Time",
                "Alaskan Standard Time"
            )
            
            # Display the list of options
            for ($i = 0; $i -lt $timeZones.Count; $i++) {
                Write-Output "$($i + 1). $($timeZones[$i])"
            }

            # Prompt the user to select a time zone
            $selection = Read-Host "Enter the number corresponding to your time zone"

            # Validate input and set the time zone
            if ($selection -match '^\d+$' -and $selection -gt 0 -and $selection -le $timeZones.Count) {
                $selectedTimeZone = $timeZones[$selection - 1]
                tzutil /s "$selectedTimeZone" *>$null
                Write-Output "Time zone set to $selectedTimeZone."
            } else {
                Write-Output "Invalid selection. Please run the script again and choose a valid number."
                return
            }
        }

        # Configure the time synchronization settings using time.nist.gov
        w32tm /config /manualpeerlist:"time.nist.gov,0x1" /syncfromflags:manual /reliable:YES /update *>$null
        Set-Service -Name w32time -StartupType Automatic *>$null
        Start-Service -Name w32time *>$null
        w32tm /resync *>$null

        Write-Output "Time settings configured and synchronized using time.nist.gov."
    } Catch {
        Write-Output "Failed to configure time settings or synchronization: $($_)"
    }
}

# Function to create a scheduled task for time synchronization at startup
function Set-TimeSyncAtStartup {
    Try {
        $taskName = "TimeSyncAtStartup"
        $action = New-ScheduledTaskAction -Execute "w32tm.exe" -Argument "/resync"
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

        # Check if the task already exists
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }

        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal
        Write-Host "Scheduled task for time synchronization at startup has been created." -ForegroundColor Green
    } Catch {
        Write-Host "Failed to create scheduled task for time synchronization: $($_)" -ForegroundColor Red
    }
}

function Disable-WindowsRecall {
    Try {
        DISM /Online /Disable-Feature /FeatureName:Recall *>$null
        Write-Host "Windows Recall feature has been disabled." -ForegroundColor Green
    } Catch {
        Write-Host "Failed to disable Windows Recall feature: $($_)" -ForegroundColor Red
    }
}

function Remove-EdgeShortcut {
    # Get the path to the current user's desktop
    $desktopPath = [Environment]::GetFolderPath("Desktop")

    # Define the name of the Edge shortcut
    $edgeShortcutName = "Microsoft Edge.lnk"

    # Construct the full path to the Edge shortcut
    $edgeShortcutPath = Join-Path -Path $desktopPath -ChildPath $edgeShortcutName

    # Check if the shortcut exists
    if (Test-Path $edgeShortcutPath) {
        # If it exists, delete the shortcut
        Remove-Item -Path $edgeShortcutPath -Force
        Write-Host "Microsoft Edge shortcut has been deleted from the desktop." -ForegroundColor Green
    } else {
        # If it doesn't exist, inform the user
        Write-Host "Microsoft Edge shortcut was not found on the desktop." -ForegroundColor Blue
    }
}

# Execute all setup tasks
Set-TimeSettings
Set-RemoteDesktop
Enable-FirewallRule -ruleGroup "remote desktop" -ruleName "Remote Desktop"
Enable-FirewallRule -ruleName "Allow ICMPv4-In" -protocol "icmpv4" -localPort "8,any"
Install-WindowsCapability -capabilityName "OpenSSH.Client~~~~0.0.1.0"
Install-WindowsCapability -capabilityName "OpenSSH.Server~~~~0.0.1.0"
Set-SSHConfiguration
Set-TimeSyncAtStartup
Disable-WindowsRecall
Remove-EdgeShortcut

Write-Host "`nSetup complete!" -ForegroundColor Green 