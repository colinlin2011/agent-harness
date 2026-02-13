# 新建 agent-harness 项目
# Usage: .\new-project.ps1 -Goal "<任务目标>" -ProjectPath <path> [-ProjectType web|cli|library|generic]

param(
    [Parameter(Mandatory = $true)]
    [string]$Goal,
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [string]$ProjectType = "generic",
    [string]$TaskFormat = "features",
    [string]$Language = "zh"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir "_common.ps1")

$harnessRoot = Get-HarnessRoot
$projectPath = $ProjectPath.Trim()

if (Test-Path $projectPath) {
    $existing = Get-ChildItem $projectPath -Force -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Error "Project path exists and is not empty: $projectPath"
    }
}

New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
$projectPath = (Resolve-Path $projectPath).Path

$config = @{
    goal       = $Goal
    projectType = $ProjectType
    taskFormat  = $TaskFormat
    maxItemsPerSession = 1
    language    = $Language
} | ConvertTo-Json -Depth 3

$configPath = Join-Path $projectPath "agent-harness-config.json"
$config | Set-Content -Path $configPath -Encoding UTF8

# 复制 rules
$rulesSrc = Join-Path $harnessRoot "templates\rules"
$rulesDst = Join-Path $projectPath ".cursor\rules"
if (Test-Path $rulesSrc) {
    New-Item -ItemType Directory -Path $rulesDst -Force | Out-Null
    Get-ChildItem $rulesSrc -File | ForEach-Object {
        Copy-Item $_.FullName -Destination $rulesDst -Force
    }
}

Write-Host "[OK] Project created: $projectPath" -ForegroundColor Green
Write-Host "[OK] agent-harness-config.json" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. .\agent-harness\scripts\run-initializer.ps1 -ProjectPath `"$projectPath`"" -ForegroundColor White
Write-Host "  2. .\agent-harness\scripts\run-continue.ps1 -ProjectPath `"$projectPath`"" -ForegroundColor White
Write-Host "     (or run-until-complete.ps1 for automatic loop)" -ForegroundColor Gray
