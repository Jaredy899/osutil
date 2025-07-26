#Requires -Version 5.1

$ErrorActionPreference = 'Stop'



function Install-Fastfetch {
    if (-not (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Fastfetch..."
        try {
            winget install -e --id fastfetch.fastfetch
        }
        catch {
            Write-Error "Failed to install Fastfetch. Please check your winget installation or try again later."
            exit 1
        }
    }
    else {
        Write-Host "Fastfetch is already installed."
    }
}

function Setup-FastfetchConfig {
    Write-Host "Copying Fastfetch config files..."
    $configPath = "$HOME/.config/fastfetch"
    if (Test-Path $configPath) {
        if (-not (Test-Path "$configPath-bak")) {
            Copy-Item -Path $configPath -Destination "$configPath-bak" -Recurse
        }
    }
    else {
        New-Item -Path $configPath -ItemType Directory -Force
    }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Jaredy899/mac/refs/heads/main/myzsh/config.jsonc" -OutFile "$configPath/config.jsonc"
}

function Setup-FastfetchShell {
    Write-Host "Configuring shell integration..."
    $profilePath = $PROFILE.CurrentUserCurrentHost
    if (-not (Test-Path $profilePath)) {
        New-Item -Path $profilePath -ItemType File -Force
    }
    if (Select-String -Path $profilePath -Pattern "fastfetch" -Quiet) {
        Write-Host "Fastfetch is already configured in your profile."
    }
    else {
        $response = Read-Host "Would you like to add fastfetch to your profile? [y/N]"
        if ($response -eq 'y') {
            Add-Content -Path $profilePath -Value "`n# Run fastfetch on shell initialization`nfastfetch"
            Write-Host "Added fastfetch to your profile."
        }
        else {
            Write-Host "Skipped adding fastfetch to shell config."
        }
    }
}


Install-Fastfetch
Setup-FastfetchConfig
Setup-FastfetchShell
