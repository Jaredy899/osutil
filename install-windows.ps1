$url = "https://github.com/Jaredy899/osutil/releases/latest/download/osutil-windows.exe"
$temp = [System.IO.Path]::GetTempFileName()
$exe = [System.IO.Path]::ChangeExtension($temp, ".exe")
Invoke-WebRequest -Uri $url -OutFile $temp -UseBasicParsing
Move-Item $temp $exe -Force
Unblock-File $exe
& $exe
Remove-Item $exe -Force