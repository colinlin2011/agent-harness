# Long-running Agent - Continue
# Usage: .\run-continue.ps1 -ProjectPath <project-path>

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath
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

$promptPath = Join-Path $harnessRoot "prompts/coding-agent.md"
$template = Get-Content $promptPath -Raw -Encoding UTF8
$prompt = Invoke-PromptTemplate -Template $template -Vars @{ GOAL = $goal }

# 4. 执行 agent
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Starting Coding Agent (Continue)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Push-Location $projectPath
try {
    & agent -p $prompt --output-format text
    Invoke-GitCommitAfterSession
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "[Done] Coding Agent finished" -ForegroundColor Green
