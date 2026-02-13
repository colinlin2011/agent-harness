# 长期运行 Agent - 继续工作任务

你正在**继续**一个长期任务。每次 session 你只完成**一项**工作，并留下清晰的状态供下一轮恢复。

## 任务总目标（提醒）

{{GOAL}}

## 当前待完成项（必须完成此项）

{{CURRENT_ITEM}}

## 开场步骤（必须按顺序执行）

1. 执行 `pwd` 确认当前工作目录
2. 读取 `claude-progress.txt`，了解之前的工作
3. 读取 `work_items.json`，查看所有项及 passes 状态
4. 执行 `git log --oneline -10`，查看最近提交
5. 若存在 `init.sh` 或 `init.ps1`，执行它以验证环境可用（Windows 用 init.ps1，Unix 用 init.sh）

## 选择并完成工作

- 在 `work_items.json` 中选择**第一个** `passes: false` 的项
- 本次 session 最多完成 **{{MAX_ITEMS}}** 项（按顺序，逐项完成）
- **实现**该项，然后**验收**：
  1. 若该项有 `verificationCommand`：在项目目录执行该命令，**必须通过**才可标记 passes
  2. 若该项有 `acceptanceCriteria`：逐条自检，全部满足才可标记 passes
  3. 若验证失败：修复代码后重跑验证，**禁止**在验证未通过时标记 passes

## 结束前必须完成

1. **验收通过后**，执行 `git add .` 并 `git commit -m "清晰的提交说明"`
2. 更新 `claude-progress.txt`，记录本次完成的内容和当前状态
3. 在 `work_items.json` 中**仅**将已验收通过的项改为 `passes: true`，不要修改 description、acceptanceCriteria、verificationCommand

## 禁止事项

- 一次完成超过 {{MAX_ITEMS}} 个 work_items
- 删除 work_items 中的任何项
- **未经实际验证就标记 passes: true**（验证未通过时必须修复，不可标记）
- 修改 work_items 的 description、acceptanceCriteria、verificationCommand

请立即开始执行。
