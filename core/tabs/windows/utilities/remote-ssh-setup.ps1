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



# Execute all setup tasks
Set-RemoteDesktop
Enable-FirewallRule -ruleGroup "remote desktop" -ruleName "Remote Desktop"
Enable-FirewallRule -ruleName "Allow ICMPv4-In" -protocol "icmpv4" -localPort "8,any"
Install-WindowsCapability -capabilityName "OpenSSH.Client~~~~0.0.1.0"
Install-WindowsCapability -capabilityName "OpenSSH.Server~~~~0.0.1.0"
Set-SSHConfiguration

Write-Host "`nSystem setup complete!" -ForegroundColor Green 