# Detect system architecture
$arch = (Get-WmiObject -Class Win32_ComputerSystem).SystemType
if ($arch -like "*ARM*" -or $arch -like "*aarch64*") {
    $url = "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-windows-arm64.exe"
    Write-Host "Detected ARM64 architecture, downloading ARM64 binary..."
} else {
    $url = "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-windows-x64.exe"
    Write-Host "Detected x64 architecture, downloading x64 binary..."
}

$temp = [System.IO.Path]::GetTempFileName()
$exe = [System.IO.Path]::ChangeExtension($temp, ".exe")
Invoke-WebRequest -Uri $url -OutFile $temp -UseBasicParsing
Move-Item $temp $exe -Force
Unblock-File $exe
& $exe
Remove-Item $exe -Force