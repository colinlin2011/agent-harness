# Run run-continue until all work_items pass or max rounds
# Usage: .\run-until-complete.ps1 -ProjectPath <path> [-MaxRounds 15] [-AllowNetwork] [-ContinueOnError]

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [int]$MaxRounds = 15,
    [switch]$AllowNetwork,
    [switch]$ContinueOnError
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$continueScript = Join-Path $scriptDir "run-continue.ps1"
$projectPath = (Resolve-Path $ProjectPath).Path
$workItemsPath = Join-Path $projectPath "work_items.json"

. (Join-Path $scriptDir "_common.ps1")

function Get-RemainingCount {
    $json = Get-Content $workItemsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $count = 0
    foreach ($item in $json.items) { if (-not $item.passes) { $count++ } }
    return $count
}

$remaining = Get-RemainingCount
$estMinutes = [math]::Max(1, [int]($remaining * 4))
Write-Host "Run until complete: $ProjectPath" -ForegroundColor Cyan
Write-Host "Max rounds: $MaxRounds | Remaining: $remaining" -ForegroundColor Gray
Write-Host "Estimated: ~$estMinutes min (assume ~4 min per item)" -ForegroundColor Gray
Write-Host ""

$logPath = $null
try {
    $logPath = Start-SessionLog -ProjectPath $projectPath -LogPrefix "until_complete"
    Write-Host "[Log] $logPath" -ForegroundColor DarkGray
} catch { }

$round = 0
$lastError = $null
while ($round -lt $MaxRounds) {
    $round++
    $remaining = Get-RemainingCount
    if ($remaining -eq 0) {
        Write-Host "All work items complete." -ForegroundColor Green
        break
    }
    Write-Host "========== Round $round | $remaining item(s) remaining ==========" -ForegroundColor Yellow
    try {
        & $continueScript -ProjectPath $projectPath -AllowNetwork:$AllowNetwork.IsPresent -NoLog
    } catch {
        $lastError = $_
        Write-Host "[ERROR] Round $round failed: $_" -ForegroundColor Red
        if (-not $ContinueOnError) {
            Write-Host "Use -ContinueOnError to skip and continue." -ForegroundColor Yellow
            break
        }
    }
    Write-Host ""
    if ($round -lt $MaxRounds) { Start-Sleep -Seconds 5 }
}

$final = Get-RemainingCount
if ($logPath) { try { Stop-SessionLog } catch { } }

if ($final -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " COMPLETE - All work items done!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    [console]::Beep(800, 300)
} elseif ($final -gt 0) {
    Write-Host "Stopped with $final item(s) unfinished after $MaxRounds rounds." -ForegroundColor Yellow
}
