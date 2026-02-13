# agent-harness 公共逻辑
# 供 run-initializer.ps1、run-continue.ps1、install-skill.ps1 调用

# 获取 agent-harness 根目录（脚本在 scripts/ 下，上级为根）
function Get-HarnessRoot {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $root = Split-Path -Parent $scriptDir
    if (-not (Test-Path $root)) {
        throw "无法定位 agent-harness 根目录: $root"
    }
    return $root
}

# 检查 Cursor CLI (agent 命令) 是否可用
function Test-CursorCLI {
    try {
        $null = Get-Command agent -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# 读取并解析任务配置
# 返回 hashtable，若校验失败则 throw
function Get-ProjectConfig {
    param(
        [string]$ProjectPath
    )
    $configPath = Join-Path $ProjectPath "agent-harness-config.json"
    if (-not (Test-Path $configPath)) {
        throw "未找到配置文件: $configPath"
    }
    $json = Get-Content $configPath -Raw -Encoding UTF8
    try {
        $config = $json | ConvertFrom-Json
    } catch {
        throw "配置文件 JSON 格式错误: $_"
    }
    if (-not $config.goal) {
        throw "配置缺少必填字段: goal"
    }
    $result = @{
        goal                = $config.goal
        projectType         = if ($config.projectType) { $config.projectType } else { "generic" }
        taskFormat          = if ($config.taskFormat) { $config.taskFormat } else { "features" }
        maxItemsPerSession  = if ($config.maxItemsPerSession) { $config.maxItemsPerSession } else { 1 }
        language            = if ($config.language) { $config.language } else { "zh" }
        verificationScript   = if ($config.verificationScript) { $config.verificationScript } else { $null }
        goalVerificationScript = if ($config.goalVerificationScript) { $config.goalVerificationScript } else { $null }
        deliverables         = if ($config.deliverables) { @($config.deliverables) } else { @() }
        feishu               = $config.feishu
        browserVerification  = if ($config.browserVerification) { $config.browserVerification } else { $null }
    }
    return $result
}

# 获取 work_items 中第一个 passes:false 的项，用于 prompt 注入
function Get-CurrentWorkItem {
    param([string]$WorkItemsPath)
    $json = Get-Content $WorkItemsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($item in $json.items) {
        if (-not $item.passes) {
            $line = "- description: $($item.description)"
            if ($item.acceptanceCriteria) {
                foreach ($c in $item.acceptanceCriteria) { $line += "`n  - 验收条件: $c" }
            }
            $vc = if ($item.verificationCommand) { $item.verificationCommand } else { "(无，需人工自检)" }
            $line += "`n  - verificationCommand: $vc"
            return $line
        }
    }
    return "(无待完成项)"
}

# 对指定项执行 verificationCommand，返回是否通过
function Invoke-ItemVerificationCommand {
    param([object]$Item, [string]$ProjectPath)
    $cmd = $Item.verificationCommand
    if (-not $cmd -or ($cmd -eq "")) { return $true }
    Push-Location $ProjectPath
    try {
        Invoke-Expression $cmd
        return ($LASTEXITCODE -eq 0)
    } catch {
        Write-Host "[WARN] verificationCommand failed: $_" -ForegroundColor Yellow
        return $false
    } finally { Pop-Location }
}

# 替换 prompt 模板中的占位符
function Invoke-PromptTemplate {
    param(
        [string]$Template,
        [hashtable]$Vars
    )
    $result = $Template
    foreach ($key in $Vars.Keys) {
        $placeHolder = "{{$key}}"
        $result = $result.Replace($placeHolder, $Vars[$key])
    }
    return $result
}

# 在项目 logs/ 目录下启动会话日志（Start-Transcript）
function Start-SessionLog {
    param(
        [string]$ProjectPath,
        [string]$LogPrefix = "session"
    )
    $logsDir = Join-Path $ProjectPath "logs"
    if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $logPath = Join-Path $logsDir "${LogPrefix}_${ts}.log"
    Start-Transcript -Path $logPath -Force | Out-Null
    return $logPath
}

function Stop-SessionLog {
    try { Stop-Transcript | Out-Null } catch { }
}

# 若配置了 verificationScript，在项目目录下执行（调用方需已 Push-Location）
function Invoke-VerificationScript {
    param([hashtable]$Config, [string]$ProjectPath)
    $script = $Config.verificationScript
    if (-not $script) { return $true }
    try {
        Invoke-Expression $script
        return $LASTEXITCODE -eq 0
    } catch {
        Write-Host "[WARN] verificationScript failed: $_" -ForegroundColor Yellow
        return $false
    }
}

# 检查 deliverables 配置中的交付物是否存在
function Test-Deliverables {
    param([hashtable]$Config, [string]$ProjectPath)
    $items = $Config.deliverables
    if (-not $items -or $items.Count -eq 0) { return @{ AllPresent = $true; Missing = @() } }
    $missing = @()
    foreach ($item in $items) {
        $path = if ($item -is [string]) { $item } else { $item.path }
        if (-not $path) { continue }
        $fullPath = Join-Path $ProjectPath $path
        if (-not (Test-Path $fullPath)) { $missing += $path }
    }
    return @{ AllPresent = ($missing.Count -eq 0); Missing = $missing }
}

# Agent 在沙箱内无法执行 git，脚本在 session 结束后代为提交
function Invoke-GitCommitAfterSession {
    param([string]$MessageSuffix = "")
    try {
        if (-not (Test-Path ".git")) {
            git init 2>$null
        }
        git config user.name 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            git config user.name "agent-harness"
            git config user.email "agent-harness@localhost"
        }
        git add . 2>$null
        $status = git status --short 2>$null
        if ($status) {
            $msg = "agent-harness: session @ $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
            if ($MessageSuffix) { $msg = "agent-harness: $MessageSuffix @ $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }
            git commit -m "$msg" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Git commit created" -ForegroundColor Green
            } else {
                Write-Host "[Note] Git commit failed (check git status)" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "[Note] Git commit skipped: $_" -ForegroundColor Yellow
    }
}
