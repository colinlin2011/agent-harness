# Long-running Agent - Continue
# Usage: .\run-continue.ps1 -ProjectPath <project-path> [-AllowNetwork] [-NoLog]

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [switch]$AllowNetwork,
    [switch]$NoLog
)

$ErrorActionPreference = "Stop"

# 加载公共逻辑
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir "_common.ps1")

$harnessRoot = Get-HarnessRoot
$projectPath = $ProjectPath.Trim()

# 1. 校验路径与必要文件
if (-not (Test-Path $projectPath)) {
    Write-Error "Project path not found: $projectPath"
}
$projectPath = (Resolve-Path $projectPath).Path

$workItemsPath = Join-Path $projectPath "work_items.json"
$progressPath = Join-Path $projectPath "claude-progress.txt"

if (-not (Test-Path $workItemsPath)) {
    Write-Error "work_items.json not found. Run run-initializer.ps1 first."
}
if (-not (Test-Path $progressPath)) {
    Write-Error "claude-progress.txt not found. Run run-initializer.ps1 first."
}

# 2. 校验 Cursor CLI
if (-not (Test-CursorCLI)) {
    Write-Error "Cursor CLI (agent) not found. Install: https://cursor.com/docs/cli"
}

# 3. 读取 config 与 prompt 模板
$config = $null
$configPath = Join-Path $projectPath "agent-harness-config.json"
if (Test-Path $configPath) {
    try { $config = Get-ProjectConfig -ProjectPath $projectPath } catch { }
}
$goal = if ($config) { $config.goal } else { "Complete the next item in work_items.json" }
$maxItems = if ($config -and $config.maxItemsPerSession) { $config.maxItemsPerSession } else { 1 }

$promptPath = Join-Path $harnessRoot "prompts/coding-agent.md"
$template = Get-Content $promptPath -Raw -Encoding UTF8
$prompt = Invoke-PromptTemplate -Template $template -Vars @{
    GOAL       = $goal
    MAX_ITEMS  = $maxItems
}

# 4. 日志（仅当非 NoLog 时）
$logPath = $null
if (-not $NoLog) {
    try {
        $logPath = Start-SessionLog -ProjectPath $projectPath -LogPrefix "session"
        Write-Host "[Log] $logPath" -ForegroundColor DarkGray
    } catch { }
}

# 5. 执行 agent
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Starting Coding Agent (Continue)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$agentArgs = @("-p", $prompt, "--output-format", "text")
if ($AllowNetwork) { $agentArgs += "--sandbox", "disabled" }
Push-Location $projectPath
try {
    & agent @agentArgs
    Invoke-GitCommitAfterSession

    # verificationScript（可选）
    if ($config -and $config.verificationScript) {
        Write-Host ""
        Write-Host "--- Running verificationScript ---" -ForegroundColor Gray
        $ok = Invoke-VerificationScript -Config $config -ProjectPath $projectPath
        if (-not $ok) { Write-Host "[WARN] verificationScript failed" -ForegroundColor Yellow }
    }

    # deliverables 检查（可选）
    if ($config -and $config.deliverables -and $config.deliverables.Count -gt 0) {
        $r = Test-Deliverables -Config $config -ProjectPath $projectPath
        if (-not $r.AllPresent) {
            Write-Host "[INFO] Missing deliverables: $($r.Missing -join ', ')" -ForegroundColor Gray
        }
    }
} finally {
    Pop-Location
}

if ($logPath) { try { Stop-SessionLog } catch { } }

Write-Host ""
Write-Host "[Done] Coding Agent finished" -ForegroundColor Green
