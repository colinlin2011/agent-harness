# Changelog

## [1.3.0] - 2026-02-13

### Added
- **验收驱动**：work_items 扩展 `acceptanceCriteria`、`verificationCommand`
- **goalVerificationScript**：全部完成后执行集成验证
- **templates/work_items.example.json**：含验收字段的 work_items 模板
- **docs/VERIFICATION.md**：验收与验证机制说明

### Changed
- **Initializer**：拆解 work_items 时必须包含 acceptanceCriteria，推荐 verificationCommand
- **Coding Agent**：必须执行 verificationCommand 且通过后才可标记 passes
- **run-until-complete**：全部完成时执行 goalVerificationScript，失败时告警

## [1.2.0] - 2026-02-13

### Added
- **飞书通知**：run-until-complete 完成/未完成、run-continue 每轮结束时可选推送至飞书群
- **_feishu.ps1**：飞书 Webhook 发送模块，支持环境变量、feishu-config.json、agent-harness-config 三种配置
- **feishu-config.example.json**：飞书配置模板
- **docs/FEISHU.md**：飞书集成完整说明（Webhook 获取、启用方式、企业应用扩展说明）

## [1.1.0] - 2026-02-13

### Added
- **new-project.ps1**：一键创建新项目，自动生成 agent-harness-config.json 和 .cursor/rules
- **run-health-check.ps1**：项目健康检查（work_items、deliverables、logs、环境）
- **run-until-complete.ps1 -ContinueOnError**：单轮失败时继续下一轮
- **预估时间**：run-until-complete 开始时输出预计耗时（按每项约 4 分钟）
- **完成通知**：全部完成时控制台提示 + 蜂鸣
- **日志持久化**：run-continue 写入 `logs/session_*.log`，run-until-complete 写入 `logs/until_complete_*.log`
- **verificationScript**：config 中可配置每轮结束后的验证命令
- **deliverables**：config 中可配置交付物路径，健康检查时校验
- **maxItemsPerSession**：真正生效，prompt 支持每轮完成 N 项
- **Initializer 支持 init.ps1**：Windows 项目同时生成 init.ps1

### Changed
- run-continue 支持 -NoLog（由 run-until-complete 调用时避免重复日志）
- agent-harness-config.example.json 增加 verificationScript、deliverables 示例

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
