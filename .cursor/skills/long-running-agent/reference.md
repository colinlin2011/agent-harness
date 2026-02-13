# Long-Running Agent 参考

## 配置 `agent-harness-config.json`

```json
{
  "goal": "任务总体目标",
  "projectType": "web|cli|library|research|document|generic",
  "taskFormat": "features|milestones|checkpoints",
  "maxItemsPerSession": 1,
  "language": "zh|en",
  "verificationScript": "python -m pytest",
  "deliverables": ["output/video/a.mp4", "README.md"]
}
```

## 状态文件

| 文件 | 说明 |
|------|------|
| work_items.json | `{"items":[{"description":"...","passes":false}]}` |
| claude-progress.txt | 进度日志，供下轮快速恢复 |
| init.sh / init.ps1 | 可选，启动/验证脚本（Unix/Windows） |
| logs/ | 会话日志（session_*.log, until_complete_*.log） |

## 运行脚本（需 Cursor CLI）

```powershell
# 新建项目
.\agent-harness\scripts\new-project.ps1 -Goal "任务目标" -ProjectPath .\my-task

# 首次初始化
.\agent-harness\scripts\run-initializer.ps1 -ProjectPath <项目路径>

# 继续工作（单次）
.\agent-harness\scripts\run-continue.ps1 -ProjectPath <项目路径>

# 循环直至完成（-AllowNetwork 需网络，-ContinueOnError 失败继续）
.\agent-harness\scripts\run-until-complete.ps1 -ProjectPath <项目路径> -AllowNetwork

# 健康检查
.\agent-harness\scripts\run-health-check.ps1 -ProjectPath <项目路径>
```

## 与 Anthropic Harness 对应

- Initializer Agent → run-initializer.ps1
- Coding Agent → run-continue.ps1
- feature_list.json → work_items.json
- claude-progress.txt → 同名
