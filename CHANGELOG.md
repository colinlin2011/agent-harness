# Changelog

## [1.0.0] - 2026-02-13

### Added
- 初始版本：长期运行 Agent 通用框架
- **run-initializer.ps1**：首次初始化，生成 work_items.json、claude-progress.txt、init.sh
- **run-continue.ps1**：继续工作，每次完成一项并更新状态
- **run-mvp-loop.ps1**：循环执行 run-continue，用于验证长期自主循环
- **Cursor Skill** (long-running-agent)：符合 Cursor Skills 规范，便于 Agent 自动发现
- **install-skill.ps1**：团队一键安装（personal / project）
- **install-ripgrep.ps1**：安装 ripgrep，解决 Agent 依赖
- **Invoke-GitCommitAfterSession**：脚本在每轮结束后代为 git 提交（因 Agent 沙箱无法执行 git）
- Git 同步脚本：初始化Git仓库.bat、配置远程仓库.bat、同步到远程.bat

### Changed
- Agent 沙箱内无法执行 git，由脚本在 session 结束后自动 add + commit
- 未配置 git user.name 时，自动使用 agent-harness 作为提交者

### Verified
- MVP 验证：HTML+JS 计数器，4 项全部完成，跨 session 恢复正常
- 长期自主循环：每轮读取 progress → 完成一项 → 更新状态 → 脚本 git 提交，下一轮正确接力
