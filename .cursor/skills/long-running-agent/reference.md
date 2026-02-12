# Long-Running Agent 参考

## 配置 `agent-harness-config.json`

```json
{
  "goal": "任务总体目标",
  "projectType": "web|cli|library|research|document|generic",
  "taskFormat": "features|milestones|checkpoints",
  "maxItemsPerSession": 1,
  "language": "zh|en"
}
```

## 状态文件

| 文件 | 说明 |
|------|------|
| work_items.json | `{"items":[{"description":"...","passes":false}]}` |
| claude-progress.txt | 进度日志，供下轮快速恢复 |
| init.sh | 可选，启动/验证脚本 |

## 运行脚本（需 Cursor CLI）

```powershell
# 首次初始化
.\agent-harness\scripts\run-initializer.ps1 -ProjectPath <项目路径>

# 继续工作
.\agent-harness\scripts\run-continue.ps1 -ProjectPath <项目路径>
```

## 与 Anthropic Harness 对应

- Initializer Agent → run-initializer.ps1
- Coding Agent → run-continue.ps1
- feature_list.json → work_items.json
- claude-progress.txt → 同名
