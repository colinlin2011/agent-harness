# 安装 Long-Running Agent Skill 到个人或项目
# 用法:
#   .\install-skill.ps1 -Target personal
#   .\install-skill.ps1 -Target project -ProjectPath <项目路径>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("personal", "project")]
    [string]$Target,

    [Parameter(Mandatory = $false)]
    [string]$ProjectPath
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$harnessRoot = Split-Path -Parent $scriptDir
$skillSrc = Join-Path $harnessRoot ".cursor\skills\long-running-agent"

if (-not (Test-Path $skillSrc)) {
    Write-Error "Skill 源目录不存在: $skillSrc"
}

if ($Target -eq "project") {
    if (-not $ProjectPath) {
        Write-Error "Target 为 project 时必须提供 -ProjectPath"
    }
    if (-not (Test-Path $ProjectPath)) {
        Write-Error "项目路径不存在: $ProjectPath"
    }
    $skillDst = Join-Path (Resolve-Path $ProjectPath).Path ".cursor\skills\long-running-agent"
} else {
    $cursorSkills = Join-Path $env:USERPROFILE ".cursor\skills"
    $skillDst = Join-Path $cursorSkills "long-running-agent"
    if (-not (Test-Path $cursorSkills)) {
        New-Item -ItemType Directory -Path $cursorSkills -Force | Out-Null
    }
}

$dstParent = Split-Path $skillDst
if (-not (Test-Path $dstParent)) {
    New-Item -ItemType Directory -Path $dstParent -Force | Out-Null
}

if (Test-Path $skillDst) {
    Remove-Item $skillDst -Recurse -Force
}
Copy-Item -Path $skillSrc -Destination $skillDst -Recurse -Force

Write-Host "[OK] Skill 已安装到: $skillDst" -ForegroundColor Green
