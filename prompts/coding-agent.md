# 长期运行 Agent - 继续工作任务

你正在**继续**一个长期任务。每次 session 你只完成**一项**工作，并留下清晰的状态供下一轮恢复。

## 任务总目标（提醒）

{{GOAL}}

## 开场步骤（必须按顺序执行）

1. 执行 `pwd` 确认当前工作目录
2. 读取 `claude-progress.txt`，了解之前的工作
3. 读取 `work_items.json`，查看所有项及 passes 状态
4. 执行 `git log --oneline -10`，查看最近提交
5. 若存在 `init.sh`，执行它以验证环境可用（或按 init.sh 说明启动服务做基本检查）

## 选择并完成工作

- 在 `work_items.json` 中选择**第一个** `passes: false` 的项
- **只完成这一项**，不要一次做多项
- 实现、测试、确保该项可验证通过

## 结束前必须完成

1. 执行 `git add .` 并 `git commit -m "清晰的提交说明"`，提交本次改动
2. 更新 `claude-progress.txt`，记录本次完成的内容和当前状态
3. 在 `work_items.json` 中**仅**将已完成的项改为 `passes: true`，不要修改 description 或其他项

## 禁止事项

- 一次完成多个 work_items
- 删除 work_items 中的任何项
- 未经实际验证就标记 passes: true
- 修改 work_items 的 description 或删除/重写项

请立即开始执行。
