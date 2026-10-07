---
name: git-commit
description: Create one or more repository-aware atomic Git commits directly from the current worktree. Use when a request includes creating commits, including commit-and-push workflows.
---

# Git Commit

直接检查改动、规划原子 commit、暂存、提交并验证结果。紧密耦合且共同实现一个目的的修改放入同一 commit；能够独立理解和撤销的修改拆分提交。

## Workflow

1. 读取适用于仓库和修改路径的 `AGENTS.md`、`CONTRIBUTING.md`、领域文档及其他仓库指令。检查 `git status --short`、已暂存和未暂存 diff，以及每个未跟踪文件。发现凭据泄露时停止并报告，避免输出凭据内容。
2. 根据用户意图和实际 diff 识别行为所有者，规划一个或多个原子 commit，确保每项改动恰好归入一个 commit。仓库规则优先于目录名、文件名、tool ID 和历史 commit；缺少会实质改变提交边界、type 或 scope 的信息时，在修改暂存区前询问用户。
3. 为当前 commit 暂存对应文件或 hunk，并使用 `git diff --cached` 核对暂存内容。保留所有不属于当前提交的用户改动。
4. 按仓库约定生成 commit message；仓库没有额外约定时使用下文格式。确认 message 完整覆盖暂存 diff，且只表达一个主要目的。
5. 执行 `git commit`。完成全部 commit 后，使用 `git status --short` 和 `git log --oneline -n <count>` 验证结果，并报告每个 commit 的 hash、标题和剩余修改。

不绕过 hooks，不更改签名方式，不使用破坏性 Git 操作，不修改历史。push、创建 PR、发布及其他外部操作仅在用户明确要求时执行。

## Commit Message

```text
<type>(<scope>): <中文标题>

1. <中文改动>
2. <中文改动>
```

- `type` 和 `scope` 使用英文；标题和正文以中文为主，专业名词保留原文。
- 标题准确概括整个 commit，末尾不加句号；标题和正文之间只保留一个空行。
- 正文使用从 `1.` 开始的连续数字列表，至少一项，列表项之间不留空行。
- 每项描述一个明确改动及其直接结果，全部内容都能由暂存 diff 支持。

### Type

| `type` | 使用场景 |
| --- | --- |
| `feat` | 新增或扩展功能 |
| `fix` | 修复缺陷 |
| `docs` | 仅修改文档 |
| `style` | 调整格式且不改变行为 |
| `refactor` | 重构实现且不新增功能或修复缺陷 |
| `perf` | 优化性能 |
| `build` | 修改构建系统、打包、编译、发布产物或 build pipeline |
| `ci` | 修改 CI 配置或脚本 |
| `chore` | 执行不改变产品行为的其他仓库维护工作 |
| `revert` | 撤销已有修改 |

type 由改动意图和行为效果决定，不由文件类别决定。依赖若服务于同一项 `feat` 或 `fix`，通常归入对应功能 commit；独立依赖维护按仓库约定使用 `chore(deps)`、`build(deps)` 或其他组合。

### Scope

- 优先使用仓库定义的行为所有者或稳定领域模块名。scope 描述“谁拥有这项行为”，而不是“文件放在哪里”。
- 仓库未定义 scope 时，检查相关代码和用户可见能力，再选择准确的英文模块名。
- 一个原子改动确实跨越多个行为所有者时，使用无空格的 `,` 分隔，例如 `backend,frontend`。
- 目录前缀、技术名称和历史 commit 只有在确实代表行为所有者时才能直接用作 scope。

## Command

使用恰好两个 `-m` 参数：第一个传递标题，第二个使用 ANSI-C quoting `$'...'` 和 `\n` 传递完整正文，避免 Git 将正文拆成多个段落。

```bash
git commit \
  -m 'feat(backend): 实现 NLP 推理服务' \
  -m $'1. 补齐 FastAPI 服务骨架、结构化日志与健康检查接口\n2. 接入 Stanza 模型资源加载和 NLP 推理流程'
```
