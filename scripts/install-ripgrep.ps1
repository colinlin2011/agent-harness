# Install ripgrep (rg) - required by Cursor CLI agent
# Run once if you see "Could not find ripgrep (rg) binary"

$rgZip = "$env:TEMP\rg.zip"
$rgDir = "$env:LOCALAPPDATA\ripgrep"

Write-Host "Downloading ripgrep..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://github.com/BurntSushi/ripgrep/releases/download/15.1.0/ripgrep-15.1.0-x86_64-pc-windows-msvc.zip" -OutFile $rgZip -UseBasicParsing

Write-Host "Extracting..." -ForegroundColor Cyan
Expand-Archive -Path $rgZip -DestinationPath $rgDir -Force

$rgExe = Get-ChildItem $rgDir -Recurse -Filter "rg.exe" | Select-Object -First 1
$rgPath = $rgExe.DirectoryName

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$rgPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$rgPath;$userPath", "User")
    Write-Host "[OK] ripgrep added to PATH. Restart terminal to use." -ForegroundColor Green
} else {
    Write-Host "[OK] ripgrep already in PATH" -ForegroundColor Green
}

& $rgExe.FullName --version
