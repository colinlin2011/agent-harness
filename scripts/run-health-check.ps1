# 项目健康检查
# Usage: .\run-health-check.ps1 -ProjectPath <path>

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir "_common.ps1")

$projectPath = (Resolve-Path $ProjectPath).Path
$workItemsPath = Join-Path $projectPath "work_items.json"
$progressPath = Join-Path $projectPath "claude-progress.txt"
$configPath = Join-Path $projectPath "agent-harness-config.json"

$ok = 0
$fail = 0
$warn = 0

function Report-Ok { param($msg) Write-Host "  [OK]   $msg" -ForegroundColor Green; $script:ok++ }
function Report-Fail { param($msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red; $script:fail++ }
function Report-Warn { param($msg) Write-Host "  [WARN] $msg" -ForegroundColor Yellow; $script:warn++ }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Agent-Harness Health Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Project: $projectPath" -ForegroundColor Gray
Write-Host ""

# 1. 必要文件
Write-Host "--- 1. Essential files ---" -ForegroundColor Gray
if (Test-Path $workItemsPath) { Report-Ok "work_items.json exists" } else { Report-Fail "work_items.json missing" }
if (Test-Path $progressPath) { Report-Ok "claude-progress.txt exists" } else { Report-Fail "claude-progress.txt missing" }
if (Test-Path $configPath) { Report-Ok "agent-harness-config.json exists" } else { Report-Fail "agent-harness-config.json missing" }
if (Test-Path (Join-Path $projectPath ".git")) { Report-Ok "Git repository initialized" } else { Report-Warn "No .git (run run-initializer first)" }
Write-Host ""

# 2. work_items 状态
Write-Host "--- 2. Work items ---" -ForegroundColor Gray
if (Test-Path $workItemsPath) {
    $json = Get-Content $workItemsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $total = $json.items.Count
    $passed = ($json.items | Where-Object { $_.passes }).Count
    $remaining = $total - $passed
    Report-Ok "Total: $total | Passed: $passed | Remaining: $remaining"
    if ($remaining -eq 0 -and $total -gt 0) { Report-Ok "All work items complete" }
    elseif ($remaining -gt 0) { Report-Warn "$remaining item(s) unfinished" }
} else { Report-Fail "Cannot read work_items" }
Write-Host ""

# 3. Cursor CLI
Write-Host "--- 3. Environment ---" -ForegroundColor Gray
if (Test-CursorCLI) { Report-Ok "Cursor CLI (agent) available" } else { Report-Fail "Cursor CLI not found" }
Write-Host ""

# 4. Config & deliverables
Write-Host "--- 4. Config & deliverables ---" -ForegroundColor Gray
if (Test-Path $configPath) {
    try {
        $config = Get-ProjectConfig -ProjectPath $projectPath
        Report-Ok "Config valid, goal: $($config.goal.Substring(0, [Math]::Min(50, $config.goal.Length)))..."
        if ($config.deliverables -and $config.deliverables.Count -gt 0) {
            $r = Test-Deliverables -Config $config -ProjectPath $projectPath
            if ($r.AllPresent) { Report-Ok "All deliverables present" }
            else { Report-Warn "Missing: $($r.Missing -join ', ')" }
        }
    } catch { Report-Fail "Config error: $_" }
} else { Report-Fail "No config" }
Write-Host ""

# 5. Logs
Write-Host "--- 5. Logs ---" -ForegroundColor Gray
$logsDir = Join-Path $projectPath "logs"
if (Test-Path $logsDir) {
    $logCount = (Get-ChildItem $logsDir -File -Filter "*.log").Count
    Report-Ok "logs/ has $logCount session log(s)"
} else { Report-Warn "No logs/ directory yet" }
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary: $ok OK, $warn warnings, $fail failures" -ForegroundColor $(if ($fail -gt 0) { "Red" } elseif ($warn -gt 0) { "Yellow" } else { "Green" })
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($fail -gt 0) { exit 1 } else { exit 0 }
