# 长期运行 Agent - 首次初始化任务

你正在执行**首次初始化**，负责为一个长期任务搭建环境和拆解计划。你**只做规划与架子搭建**，不实现具体功能。

## 任务目标

{{GOAL}}

## 项目类型

{{PROJECT_TYPE}}

## 任务拆解格式

按「{{TASK_FORMAT}}」形式拆解，每项需可独立完成、**可验收**。

## 验收驱动原则（必须遵循）

拆解 work_items 时，**先设计验收标准，再写实现描述**。每项需包含：

- **acceptanceCriteria**（必填）：1～5 条可检查的验收条件，如「main.py 存在且可 import」「pytest 通过」
- **verificationCommand**（推荐）：可自动执行的验证命令，如 `python -m pytest tests/`、`npm test`。若能自动化则务必填写

完整示例见 `agent-harness/templates/work_items.example.json`（若可访问）

## 你必须完成的工作

1. **创建 `work_items.json`**
   - 结构：`{"items":[{"description":"...","acceptanceCriteria":["条件1","条件2"],"verificationCommand":"可选","passes":false}]}`
   - 每项必须有 **acceptanceCriteria** 数组（至少 1 条）
   - 可自动验证的项必须有 **verificationCommand**
   - 所有 `passes` 初始均为 `false`
   - 禁止删除已有项，禁止大范围改写

2. **创建 `claude-progress.txt`**
   - 简要说明本次初始化的内容
   - 供后续 session 快速了解项目状态

3. **创建环境初始化脚本**（若 projectType 为 web/cli/library）
   - **init.sh**（Unix/macOS）：用于启动开发环境或验证基本可运行
   - **init.ps1**（Windows）：等价逻辑，可用 `python -m http.server 8000` 或 `npx serve .`
   - 纯 HTML+JS 项目：两个脚本都创建；其他类型可只创建 init.sh 或写简单说明

4. **Git 与 .gitignore**
   - 如当前目录无 `.git`，执行 `git init`
   - 若创建 `.gitignore`，加入 `logs/` 以忽略 agent-harness 会话日志
   - 将上述文件加入并做首次 commit，commit message 简明

## 禁止事项

- 不要实现具体功能代码（除非是最小骨架，如空的 index.html）
- 不要一次做太多，只搭架子
- 不要修改 work_items 的 description，只设置 passes

请立即开始执行。
