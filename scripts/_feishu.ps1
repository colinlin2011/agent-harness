# 飞书通知模块
# 支持：Webhook 机器人消息
# 配置来源（优先级）：环境变量 > feishu-config.json > agent-harness-config.json

# 获取飞书配置（合并多来源）
function Get-FeishuConfig {
    param([string]$ProjectPath, [hashtable]$ProjectConfig = $null)
    $webhook = $env:FEISHU_WEBHOOK
    $notifyOnComplete = $true
    $notifyOnRound = $false
    $notifyOnError = $true

    $feishuPath = Join-Path $ProjectPath "feishu-config.json"
    if (Test-Path $feishuPath) {
        try {
            $fc = Get-Content $feishuPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if (-not $webhook -and $fc.webhook) { $webhook = $fc.webhook }
            if ($null -ne $fc.notifyOnComplete) { $notifyOnComplete = [bool]$fc.notifyOnComplete }
            if ($null -ne $fc.notifyOnRound) { $notifyOnRound = [bool]$fc.notifyOnRound }
            if ($null -ne $fc.notifyOnError) { $notifyOnError = [bool]$fc.notifyOnError }
        } catch { }
    }

    if ($ProjectConfig -and $ProjectConfig.feishu) {
        $f = $ProjectConfig.feishu
        if (-not $webhook -and $f.webhook) { $webhook = $f.webhook }
        if ($null -ne $f.notifyOnComplete) { $notifyOnComplete = [bool]$f.notifyOnComplete }
        if ($null -ne $f.notifyOnRound) { $notifyOnRound = [bool]$f.notifyOnRound }
        if ($null -ne $f.notifyOnError) { $notifyOnError = [bool]$f.notifyOnError }
    }

    return @{
        webhook         = $webhook
        notifyOnComplete = $notifyOnComplete
        notifyOnRound   = $notifyOnRound
        notifyOnError   = $notifyOnError
        enabled         = [bool]($webhook -and $webhook.Trim().Length -gt 0)
    }
}

# 发送飞书 Webhook 消息（文本）
function Send-FeishuMessage {
    param(
        [string]$Text,
        [string]$Title = $null,
        [hashtable]$Config = $null
    )
    if (-not $Config -or -not $Config.enabled) { return $false }
    $url = $Config.webhook.Trim()
    if (-not $url) { return $false }

    $body = @{
        msg_type = "text"
        content  = @{ text = $Text }
    } | ConvertTo-Json -Depth 3 -Compress

    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json; charset=utf-8" -TimeoutSec 10
        if ($response.code -and $response.code -ne 0) {
            Write-Host "[Feishu] API error: $($response.msg)" -ForegroundColor Yellow
            return $false
        }
        return $true
    } catch {
        Write-Host "[Feishu] Send failed: $_" -ForegroundColor Yellow
        return $false
    }
}

# 发送富文本卡片（可选，用于更丰富的通知）
function Send-FeishuCard {
    param(
        [string]$Title,
        [string]$Content,
        [hashtable]$Config = $null
    )
    if (-not $Config -or -not $Config.enabled) { return $false }
    $url = $Config.webhook.Trim()
    if (-not $url) { return $false }

    $card = @{
        config = @{ wide_screen_mode = $true }
        elements = @(
            @{
                tag  = "div"
                text = @{
                    tag     = "lark_md"
                    content = "**$Title**\n\n$Content"
                }
            }
        )
    }
    $body = @{
        msg_type = "interactive"
        card    = $card
    } | ConvertTo-Json -Depth 5 -Compress

    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json; charset=utf-8" -TimeoutSec 10
        if ($response.code -and $response.code -ne 0) {
            Write-Host "[Feishu] API error: $($response.msg)" -ForegroundColor Yellow
            return $false
        }
        return $true
    } catch {
        Write-Host "[Feishu] Send failed: $_" -ForegroundColor Yellow
        return $false
    }
}
