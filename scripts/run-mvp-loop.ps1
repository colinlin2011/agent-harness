# MVP Loop - Run run-continue multiple times to verify long-term autonomous loop
# Usage: .\run-mvp-loop.ps1 -ProjectPath <path> -Count <times>

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [int]$Count = 2
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$continueScript = Join-Path $scriptDir "run-continue.ps1"

Write-Host "MVP Loop: Running run-continue $Count times" -ForegroundColor Cyan
Write-Host ""

for ($i = 1; $i -le $Count; $i++) {
    Write-Host "========== Round $i / $Count ==========" -ForegroundColor Yellow
    & $continueScript -ProjectPath $ProjectPath
    Write-Host ""
    if ($i -lt $Count) {
        Write-Host "Waiting 5s before next round..." -ForegroundColor Gray
        Start-Sleep -Seconds 5
    }
}

Write-Host "MVP Loop finished. Check work_items.json and claude-progress.txt" -ForegroundColor Green
