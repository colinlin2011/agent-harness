# Agent Harness - 长期运行 Agent 通用框架

通过任务配置 + Cursor CLI 实现可复用的长期运行 Agent 能力，支持多 session 增量完成复杂任务。

## 前置条件

- **Cursor CLI**：需已安装 `agent` 命令
  - Windows: `irm 'https://cursor.com/install?win32=true' | iex`
  - 首次使用需执行 `agent login` 完成认证
- **ripgrep (rg)**：Cursor Agent 依赖，若报错可运行 `.\agent-harness\scripts\install-ripgrep.ps1`
- **PowerShell**
- **Git**

## 快速开始

### 1. 新建任务

```powershell
# 创建项目目录
mkdir D:\Colin\Cursor\my-task
cd D:\Colin\Cursor\my-task

# 创建配置文件（参考 agent-harness-config.example.json）
# 编辑 agent-harness-config.json，填写 goal

# 执行首次初始化（生成 work_items.json、claude-progress.txt、init.sh）
..\agent-harness\scripts\run-initializer.ps1 -ProjectPath .
```

### 2. 继续工作（手动或定时）

```powershell
..\agent-harness\scripts\run-continue.ps1 -ProjectPath D:\Colin\Cursor\my-task
```

### 3. 定时执行（Windows 任务计划程序）

- 程序：`powershell.exe`
- 参数：`-ExecutionPolicy Bypass -File "D:\Colin\Cursor\agent-harness\scripts\run-continue.ps1" -ProjectPath "D:\Colin\Cursor\my-task"`
- 触发器：按需设置

## 配置说明

| 字段 | 必填 | 说明 |
|------|------|------|
| goal | 是 | 任务总体目标 |
| projectType | 否 | web / cli / library / research / document / generic |
| taskFormat | 否 | features / milestones / checkpoints |
| maxItemsPerSession | 否 | 默认 1 |
| language | 否 | zh / en |

## 团队接入

### 安装 Skill 到个人（全局可用）

```powershell
.\agent-harness\scripts\install-skill.ps1 -Target personal
```

### 安装到项目（随项目版本控制）

```powershell
.\agent-harness\scripts\install-skill.ps1 -Target project -ProjectPath D:\Colin\Cursor\my-task
```

## MVP 验证（长期自主循环）

验证「每次 run-continue 读取 progress、完成一项、更新状态，下一轮继续」的循环有效性。

**前置**：`agent login`（首次）、ripgrep（若报错运行 `install-ripgrep.ps1`）

```powershell
# 1. 首次初始化
.\agent-harness\scripts\run-initializer.ps1 -ProjectPath .\agent-harness-mvp

# 2. 继续工作（单次）
.\agent-harness\scripts\run-continue.ps1 -ProjectPath .\agent-harness-mvp

# 3. 循环验证（连续执行 2 次，验证跨 session 恢复）
.\agent-harness\scripts\run-mvp-loop.ps1 -ProjectPath .\agent-harness-mvp -Count 2
```

**预期**：每轮完成 1 项、更新 claude-progress.txt、work_items 中对应项 passes: true，下一轮选取下一项。脚本在每轮结束后自动执行 git 提交（Agent 沙箱内无法执行 git，由脚本代为提交）。

## 故障排查

### 未找到 agent 命令

- 确认已安装 Cursor CLI：https://cursor.com/docs/cli
- Windows: `irm 'https://cursor.com/install?win32=true' | iex`
- 重启终端或重启 Cursor 后再试

### 配置 JSON 格式错误

- 检查 `agent-harness-config.json` 是否为合法 JSON
- 确保 `goal` 字段存在且非空

### work_items.json 未生成

- 确认已先运行 `run-initializer.ps1`
- 检查 Initializer 输出是否有报错

## 同步到远程

agent-harness 可作为独立仓库推送。在 agent-harness 目录下：

1. 双击 `初始化Git仓库.bat`
2. 在 GitHub/Gitee 创建新仓库
3. 双击 `配置远程仓库.bat`，输入仓库地址
4. 双击 `同步到远程.bat`

## CHANGELOG

见 [CHANGELOG.md](CHANGELOG.md)。
