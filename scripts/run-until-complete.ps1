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
. (Join-Path $scriptDir "_feishu.ps1")

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
$projectConfig = $null
try { $projectConfig = Get-ProjectConfig -ProjectPath $projectPath } catch { }
$feishuConfig = Get-FeishuConfig -ProjectPath $projectPath -ProjectConfig $projectConfig

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
    $goalVerifyOk = $true
    if ($projectConfig -and $projectConfig.goalVerificationScript) {
        Write-Host ""
        Write-Host "--- 集成验证 (goalVerificationScript) ---" -ForegroundColor Gray
        Push-Location $projectPath
        try {
            Invoke-Expression $projectConfig.goalVerificationScript
            $goalVerifyOk = ($LASTEXITCODE -eq 0)
        } catch {
            Write-Host "[WARN] goalVerificationScript failed: $_" -ForegroundColor Yellow
            $goalVerifyOk = $false
        } finally { Pop-Location }
        if (-not $goalVerifyOk) {
            Write-Host "[WARN] 集成验证未通过，请检查 goalVerificationScript" -ForegroundColor Yellow
        }
    }
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " COMPLETE - All work items done!" -ForegroundColor Green
    if (-not $goalVerifyOk) { Write-Host " (集成验证未通过，请人工检查)" -ForegroundColor Yellow }
    Write-Host "========================================" -ForegroundColor Green
    [console]::Beep(800, 300)
    if ($feishuConfig.notifyOnComplete) {
        $msg = "[agent-harness] 任务全部完成`n项目: $projectPath`n共 $round 轮，全部通过"
        if (-not $goalVerifyOk) { $msg += "`n(集成验证未通过)" }
        Send-FeishuMessage -Text $msg -Config $feishuConfig | Out-Null
    }
} elseif ($final -gt 0) {
    Write-Host "Stopped with $final item(s) unfinished after $MaxRounds rounds." -ForegroundColor Yellow
    if ($feishuConfig.notifyOnError -and $feishuConfig.enabled) {
        $msg = "[agent-harness] 任务未完成`n项目: $projectPath`n剩余 $final 项，共 $round 轮"
        Send-FeishuMessage -Text $msg -Config $feishuConfig | Out-Null
    }
}
