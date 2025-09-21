# Ruby installer via mise

$esc   = [char]27
$Yellow= "${esc}[33m"
$Green = "${esc}[32m"
$Red   = "${esc}[31m"
$Cyan  = "${esc}[36m"
$Reset = "${esc}[0m"

function Test-CommandExists([string]$name) { Get-Command $name -ErrorAction SilentlyContinue }

function Install-BuildDependencies {
    Write-Host "${Yellow}Checking Windows build environment...${Reset}"
    
    # Check for Visual Studio Build Tools or Visual Studio
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vsWhere) {
        $vsInstall = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($vsInstall) {
            Write-Host "${Cyan}Visual Studio Build Tools found at: $vsInstall${Reset}"
        } else {
            Write-Host "${Yellow}Visual Studio Build Tools not found. Installing via winget...${Reset}"
            try {
                winget install Microsoft.VisualStudio.2022.BuildTools --silent --accept-package-agreements --accept-source-agreements
            } catch {
                Write-Host "${Yellow}Failed to install via winget. Please install Visual Studio Build Tools manually.${Reset}"
            }
        }
    } else {
        Write-Host "${Yellow}Visual Studio Installer not found. Installing via winget...${Reset}"
        try {
            winget install Microsoft.VisualStudio.2022.BuildTools --silent --accept-package-agreements --accept-source-agreements
        } catch {
            Write-Host "${Yellow}Failed to install via winget. Please install Visual Studio Build Tools manually.${Reset}"
        }
    }
    
    # Install Git if not present (required for some Ruby gems)
    if (-not (Test-CommandExists git)) {
        Write-Host "${Yellow}Installing Git...${Reset}"
        try {
            winget install Git.Git --silent --accept-package-agreements --accept-source-agreements
        } catch {
            Write-Host "${Yellow}Failed to install Git via winget. Please install Git manually.${Reset}"
        }
    }
    
    Write-Host "${Cyan}Note: For native gem compilation, ensure you have Visual Studio Build Tools installed.${Reset}"
    Write-Host "${Cyan}Ruby on Windows typically uses pre-compiled binaries, but some gems may need compilation.${Reset}"
}

Write-Host "${Yellow}Installing Ruby via mise...${Reset}"

# Install build dependencies first
Install-BuildDependencies

# Install mise if not available
if (-not (Test-CommandExists mise)) {
  Write-Host "${Yellow}Installing mise...${Reset}"
  try {
    Invoke-WebRequest -Uri "https://mise.run/install.ps1" -OutFile "$env:TEMP\mise-install.ps1"
    & "$env:TEMP\mise-install.ps1"
    Remove-Item "$env:TEMP\mise-install.ps1" -ErrorAction SilentlyContinue
  } catch { Write-Host "${Red}Failed to install mise: $($_.Exception.Message)${Reset}"; exit 1 }
}

# Install latest stable Ruby
try {
  mise use -g ruby@latest
  Write-Host "${Green}Ruby installed via mise. Restart your shell to use Ruby.${Reset}"
  Write-Host "${Cyan}Note: For native gem compilation, ensure Visual Studio Build Tools are installed.${Reset}"
  
  # Troubleshooting guidance
  Write-Host "${Cyan}Troubleshooting tips:${Reset}"
  Write-Host "${Cyan}- If gem compilation fails, ensure Visual Studio Build Tools are installed${Reset}"
  Write-Host "${Cyan}- For 'C compiler cannot create executables' error, check build environment${Reset}"
  Write-Host "${Cyan}- Some gems may require specific Windows SDK versions${Reset}"
  Write-Host "${Cyan}- For more help, see: https://github.com/rbenv/ruby-build/wiki${Reset}"
} catch { Write-Host "${Red}Failed to install Ruby via mise: $($_.Exception.Message)${Reset}"; exit 1 }


