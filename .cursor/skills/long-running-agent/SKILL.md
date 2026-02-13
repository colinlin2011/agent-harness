---
name: long-running-agent
description: Enables long-running agent workflows across multiple sessions. Use when the user describes a complex task spanning hours or days, multi-session coding, incremental project development, or asks to set up persistent agent handoffs. Handles feature/milestone/checkpoint tracking and progress files.
---

# Long-Running Agent 工作流程

为跨多 session 的复杂任务提供结构化流程，避免 Agent 遗忘进度或一次性做太多。

## 核心协议

### 开场（每次 session 开始时）

1. 读取 `claude-progress.txt` 和 `work_items.json`
2. 查看 `git log --oneline -10`
3. 若有 `init.sh` 或 `init.ps1`，先执行基本验证

### 执行

- 每次只完成 `work_items.json` 中第一个 `passes: false` 的项
- 实现该项后**验收**：若有 `verificationCommand` 则执行，**必须通过**才可标记 passes；若有 `acceptanceCriteria` 则逐条自检

### 结束（session 结束前）

1. `git commit` 并写清晰 message
2. 更新 `claude-progress.txt`
3. 仅将已**验收通过**的项改为 `passes: true`，不改动 description、acceptanceCriteria、verificationCommand

## 禁止

- 一次完成多个 work_items
- 删除或改写 work_items 的 description、acceptanceCriteria、verificationCommand
- **未经 verificationCommand 通过或 acceptanceCriteria 自检就标记 passes: true**

## 更多

- 完整配置与用法见 [reference.md](reference.md)
- 示例见 [examples.md](examples.md)
