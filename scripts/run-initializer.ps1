# Long-running Agent - Initializer
# Usage: .\run-initializer.ps1 -ProjectPath <project-path>

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    Write-Error "ProjectPath is required. Usage: .\run-initializer.ps1 -ProjectPath <path>"
}

# Load common
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
. (Join-Path $scriptDir "_common.ps1")

$harnessRoot = Get-HarnessRoot
$projectPath = $ProjectPath.Trim()

# 1. 校验 ProjectPath
if (-not (Test-Path $projectPath)) {
    Write-Error "Project path not found: $projectPath"
}
$projectPath = (Resolve-Path $projectPath).Path

# 2. 校验 agent-harness-config.json 存在且含 goal
$config = Get-ProjectConfig -ProjectPath $projectPath
Write-Host "[OK] Config loaded, goal: $($config.goal)" -ForegroundColor Green

# 3. 校验 Cursor CLI
if (-not (Test-CursorCLI)) {
    Write-Error "Cursor CLI (agent) not found. Install: https://cursor.com/docs/cli"
}

# 4. 复制 rules 到项目
$rulesSrc = Join-Path $harnessRoot "templates\rules"
$rulesDst = Join-Path $projectPath ".cursor\rules"
if (Test-Path $rulesSrc) {
    if (-not (Test-Path $rulesDst)) {
        New-Item -ItemType Directory -Path $rulesDst -Force | Out-Null
    }
    Get-ChildItem $rulesSrc -File | ForEach-Object {
        Copy-Item $_.FullName -Destination $rulesDst -Force
    }
    Write-Host "[OK] Rules copied to project" -ForegroundColor Green
}

# 5. 读取并填充 initializer prompt
$promptPath = Join-Path $harnessRoot "prompts\initializer.md"
$template = Get-Content $promptPath -Raw -Encoding UTF8
$taskFormatMap = @{
    "features"    = "feature"
    "milestones"  = "milestone"
    "checkpoints" = "checkpoint"
}
$taskFormatLabel = $taskFormatMap[$config.taskFormat]
if (-not $taskFormatLabel) { $taskFormatLabel = "feature" }
$prompt = Invoke-PromptTemplate -Template $template -Vars @{
    GOAL         = $config.goal
    PROJECT_TYPE = $config.projectType
    TASK_FORMAT  = $taskFormatLabel
}

# 6. 执行 agent
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Starting Initializer Agent" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Push-Location $projectPath
try {
    & agent -p $prompt --output-format text
    Invoke-GitCommitAfterSession -MessageSuffix "initialization"
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "[Done] Initializer finished" -ForegroundColor Green
