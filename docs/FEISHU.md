# 飞书集成

agent-harness 支持在任务完成或每轮结束时，通过飞书机器人 Webhook 发送通知。

## 一、获取 Webhook 地址

1. 在飞书群聊中，点击群设置 → **群机器人** → **添加机器人**
2. 选择 **自定义机器人**
3. 设置名称（如「agent-harness」），勾选 **群聊** 等所需权限
4. 复制生成的 **Webhook 地址**，形如：
   ```
   https://open.feishu.cn/open-apis/bot/v2/hook/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```

## 二、启用方式（任选其一）

### 方式 A：环境变量（推荐，便于公司环境统一配置）

在系统或用户环境变量中添加：

```
FEISHU_WEBHOOK=https://open.feishu.cn/open-apis/bot/v2/hook/你的webhook-id
```

- Windows：`系统属性` → `高级` → `环境变量`
- 或在执行脚本前：`$env:FEISHU_WEBHOOK="https://..."; .\run-until-complete.ps1 ...`

### 方式 B：项目级配置文件

在**项目目录**下创建 `feishu-config.json`（建议加入 .gitignore，避免泄露）：

```json
{
  "webhook": "https://open.feishu.cn/open-apis/bot/v2/hook/你的webhook-id",
  "notifyOnComplete": true,
  "notifyOnRound": false,
  "notifyOnError": true
}
```

复制模板：
```powershell
Copy-Item agent-harness\templates\feishu-config.example.json 项目目录\feishu-config.json
# 编辑 feishu-config.json，填入 webhook
```

并在项目 `.gitignore` 中添加：`feishu-config.json`

### 方式 C：主配置中嵌入

在 `agent-harness-config.json` 中增加 `feishu` 节点：

```json
{
  "goal": "任务目标...",
  "feishu": {
    "webhook": "https://open.feishu.cn/open-apis/bot/v2/hook/你的webhook-id",
    "notifyOnComplete": true,
    "notifyOnRound": false,
    "notifyOnError": true
  }
}
```

**优先级**：环境变量 > feishu-config.json > agent-harness-config.json

## 三、配置项说明

| 字段 | 说明 | 默认 |
|------|------|------|
| webhook | 飞书机器人 Webhook 地址 | 必填 |
| notifyOnComplete | run-until-complete 全部完成时通知 | true |
| notifyOnRound | run-continue 每轮结束时通知 | false |
| notifyOnError | 任务未完成/异常时通知 | true |

## 四、通知触发时机

| 脚本 | 时机 |
|------|------|
| run-until-complete | 全部完成（12/12 项通过）→ 发送「任务全部完成」 |
| run-until-complete | 未完成退出（如超轮数）→ 发送「任务未完成，剩余 N 项」 |
| run-continue | 每轮结束（仅当 notifyOnRound=true 时）→ 发送「本轮完成，剩余 N 项」 |

## 五、企业应用与 API（扩展）

若使用**企业自建应用**（app_id + app_secret）发送消息，需调用飞书开放平台 API 获取 tenant_access_token，再调发送接口。当前框架仅支持 **Webhook 机器人**，企业应用能力可作为后续扩展。

如需云文档、多维表格等更深度集成，可基于飞书开放平台文档自行扩展 `_feishu.ps1`。

## 六、快速校验

配置完成后，可用以下命令测试发送（需将 `YOUR_WEBHOOK` 替换为实际地址）：

```powershell
$body = '{"msg_type":"text","content":{"text":"[agent-harness] 飞书通知测试"}}'
Invoke-RestMethod -Uri "YOUR_WEBHOOK" -Method Post -Body $body -ContentType "application/json; charset=utf-8"
```

若群内收到消息，说明 Webhook 配置正确。
