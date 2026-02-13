# 验收驱动与验证机制

agent-harness 采用**验收驱动**范式，确保每项子任务和整体目标均可验证。

## 一、子任务验证（per work_item）

### work_items 结构

```json
{
  "items": [
    {
      "description": "创建项目骨架：main.py、config.py、requirements.txt",
      "acceptanceCriteria": [
        "main.py 存在且可 import config",
        "pip install -r requirements.txt 无报错"
      ],
      "verificationCommand": "python -c \"import main; print('OK')\"",
      "passes": false
    }
  ]
}
```

| 字段 | 必填 | 说明 |
|------|------|------|
| description | 是 | 实现描述 |
| acceptanceCriteria | 是 | 1～5 条可检查的验收条件 |
| verificationCommand | 推荐 | 可自动执行的验证命令 |
| passes | 是 | 初始 false |

### 验证流程

1. Agent 完成实现后，**必须**执行该项的 `verificationCommand`
2. 若 `verificationCommand` 返回非 0，Agent 需修复代码并重跑，**禁止**在未通过时标记 passes
3. 若有 `acceptanceCriteria` 但无 `verificationCommand`，Agent 需逐条自检，全部满足才可标记 passes

### 示例

- Python：`verificationCommand`: `"python -m pytest tests/test_item.py -v"`
- Node：`verificationCommand`: `"npm test"`
- 文档：`acceptanceCriteria`: `["文档包含 X 章节", "无错别字"]`（人工自检）

## 二、整体集成验证（goalVerificationScript）

全部 work_items 通过后，框架会执行 `agent-harness-config.json` 中的 `goalVerificationScript`：

```json
{
  "goalVerificationScript": "python -m pytest tests/integration -v"
}
```

- 在项目目录下执行
- 若失败，会打印 `[WARN] 集成验证未通过`，飞书通知中也会注明
- 用于端到端测试、集成测试、整体目标校验

## 三、三层验证关系

```
┌─────────────────────────────────────────────────────────┐
│  goalVerificationScript（全部完成后，整体集成验证）      │
└─────────────────────────────────────────────────────────┘
                            ↑
┌─────────────────────────────────────────────────────────┐
│  work_item.verificationCommand（每项完成时，单项验证）  │
└─────────────────────────────────────────────────────────┘
                            ↑
┌─────────────────────────────────────────────────────────┐
│  work_item.acceptanceCriteria（每项完成时，人工/自检）   │
└─────────────────────────────────────────────────────────┘
```

## 四、浏览器验证（配置预留）

当任务成果需在浏览器中验证时，可配置 `browserVerification`（暂未启用，预留扩展）：

```json
{
  "browserVerification": {
    "enabled": false,
    "baseUrl": "http://localhost:3000",
    "mcpRequired": false
  }
}
```

- **enabled**：是否启用浏览器验证（当前框架未使用）
- **baseUrl**：本地开发服务地址，供 Browser MCP 打开
- **mcpRequired**：是否需要配置 Browser MCP 才能验证

需要时可在 Cursor 中配置 Browser MCP，并在 prompt 中增加浏览器验证指引。

## 五、向后兼容

- 旧项目若 work_items 无 `acceptanceCriteria`、`verificationCommand`，Agent 仍按「实现后自评」执行
- 建议新项目由 Initializer 生成含验收字段的 work_items，以提升质量
