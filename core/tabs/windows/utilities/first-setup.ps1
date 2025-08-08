# Minimal ANSI colors (PS7/Windows Terminal/TUI)
$esc   = [char]27
$Cyan  = "${esc}[36m"
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

function Set-RemoteDesktop {
    Try {
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Value 0 -PropertyType DWORD -Force *>$null
        Write-Host "${Green}Remote Desktop enabled.${Reset}"
    } Catch {
        Write-Host "${Red}Failed to enable Remote Desktop: $($_)${Reset}"
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
        Write-Host "${Green}${ruleName} rule enabled.${Reset}"
    } Catch {
        Write-Host "${Red}Failed to enable ${ruleName} rule: $($_)${Reset}"
    }
}

function Install-WindowsCapability {
    param (
        [string]$capabilityName
    )
    if ((Get-WindowsCapability -Online | Where-Object Name -like "$capabilityName*").State -ne 'Installed') {
        Try {
            Add-WindowsCapability -Online -Name $capabilityName *>$null
            Write-Host "${Green}${capabilityName} installed successfully.${Reset}"
        } Catch {
            Write-Host "${Red}Failed to install ${capabilityName}: $($_)${Reset}"
        }
    } else {
        Write-Host "${Blue}${capabilityName} is already installed.${Reset}"
    }
}

function Set-SSHConfiguration {
    Try {
        Start-Service sshd *>$null
        Set-Service -Name sshd -StartupType 'Automatic' *>$null
        Write-Host "${Green}SSH service started and set to start automatically.${Reset}"
    } Catch {
        Write-Host "${Red}Failed to configure SSH service: $($_)${Reset}"
    }

    Try {
        $firewallRuleExists = Get-NetFirewallRule -Name 'sshd' -ErrorAction SilentlyContinue
        if ($null -eq $firewallRuleExists) {
            Try {
                New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 *>$null
                Write-Host "${Green}Firewall rule for OpenSSH Server (sshd) created successfully.${Reset}"
            } Catch {
                Write-Host "${Red}Failed to create firewall rule for OpenSSH Server (sshd): $($_)${Reset}"
            }
        } else {
            Write-Host "${Blue}Firewall rule for OpenSSH Server (sshd) already exists.${Reset}"
        }
    } Catch {
        Write-Host "${Red}Failed to check for existing firewall rule: $($_)${Reset}"
    }

    Try {
        New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Program Files\PowerShell\7\pwsh.exe" -PropertyType String -Force *>$null
        Write-Host "${Green}Default shell for OpenSSH set to PowerShell 7.${Reset}"
    } Catch {
        Write-Host "${Red}Failed to set default shell for OpenSSH: $($_)${Reset}"
    }
}



# Execute all setup tasks
Set-RemoteDesktop
Enable-FirewallRule -ruleGroup "remote desktop" -ruleName "Remote Desktop"
Enable-FirewallRule -ruleName "Allow ICMPv4-In" -protocol "icmpv4" -localPort "8,any"
Install-WindowsCapability -capabilityName "OpenSSH.Client~~~~0.0.1.0"
Install-WindowsCapability -capabilityName "OpenSSH.Server~~~~0.0.1.0"
Set-SSHConfiguration

Write-Host "${Green}`nSystem setup complete!${Reset}"