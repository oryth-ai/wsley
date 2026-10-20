---
name: git-commit
description: Create repository-aware atomic Git commits when the user requests committing current changes, including commit-and-push workflows. Not for discussing commit conventions, reviewing changes without committing, or maintaining this skill.
---

# Git Commit

按当前请求检查改动、组织原子提交、暂存并创建 commit。紧密耦合且共同实现一个目的的修改放入同一 commit；能够独立理解和撤销的修改拆分提交。

仅在用户要求创建提交，或明确调用本技能执行提交时运行。讨论提交规范、审查或维护技能、读取本文件，不构成提交授权。已有明确授权时直接执行，不重复请求确认。

## 范围与仓库状态

读取适用于仓库和修改路径的 `AGENTS.md`、`CONTRIBUTING.md`、领域文档及其他仓库指令。确认当前仓库与分支，检查 `git status --short`、已暂存和未暂存 diff，以及请求涉及的未跟踪文件。发现凭据泄露时停止并报告，避免输出凭据内容。

识别未解决冲突和尚未结束的合并、变基或其他 Git 操作。当前请求未涵盖其处理时，说明状态并停止提交，不自行继续、终止或跳过这些操作，也不为完成提交切换分支或修改历史。

按用户意图确定提交范围，区分本次任务、用户已有修改和其他工作。用户指定仅提交暂存内容时，以暂存版本为准，保留同一文件中的未暂存修改。范围内没有可提交内容时直接说明，不创建空提交。

## 原子提交与暂存

根据实际 diff 识别行为所有者，组织一个或多个原子 commit，使范围内每项改动恰好归入一个 commit。仓库规则优先于目录名、文件名、tool ID 和历史 commit；只有缺少会实质改变提交边界、type 或 scope 的依据时，才在修改暂存区前澄清。

为当前 commit 暂存对应文件或 hunk，使用 `git diff --cached` 核对实际准备提交的版本。保留用户的部分暂存安排，不通过整文件暂存、重置或覆盖文件混入其他工作。暂存区含有本次范围外内容时，采用能保留其内容和暂存状态的选择性提交方式；无法可靠分离时先澄清范围。

通读准备提交的完整文件，确认提交只表达一个主要目的，关联调用方和资源已同步，必要验证针对实际提交版本。按仓库约定生成 commit message；仓库没有额外约定时采用下文格式。

## 提交信息

```text
<type>(<scope>): <中文标题>

1. <中文改动>
2. <中文改动>
```

- `type` 和 `scope` 使用英文；标题和正文以中文为主，专业名词保留原文。
- 标题准确概括整个 commit，末尾不加句号；标题和正文之间只保留一个空行。
- 正文使用从 `1.` 开始的连续数字列表，至少一项，列表项之间不留空行。
- 每项描述一个明确改动及其直接结果，全部内容都能由暂存 diff 支持。

### 类型

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

### 范围

- 优先使用仓库定义的行为所有者或稳定领域模块名。scope 描述“谁拥有这项行为”，而不是“文件放在哪里”。
- 仓库未定义 scope 时，检查相关代码和用户可见能力，再选择准确的英文模块名。
- 一个原子改动确实跨越多个行为所有者时，使用无空格的 `,` 分隔，例如 `backend,frontend`。
- 目录前缀、技术名称和历史 commit 只有在确实代表行为所有者时才能直接用作 scope。

## 执行与结果

使用恰好两个 `-m` 参数：第一个传递标题，第二个使用 ANSI-C quoting `$'...'` 和 `\n` 传递完整正文，避免 Git 将正文拆成多个段落。

```bash
git commit \
  -m 'feat(backend): 实现 NLP 推理服务' \
  -m $'1. 补齐 FastAPI 服务骨架、结构化日志与健康检查接口\n2. 接入 Stanza 模型资源加载和 NLP 推理流程'
```

执行 `git commit`，保留仓库的 hooks 和签名设置，不绕过检查或使用破坏性 Git 操作。提交失败时说明原因并保留改动；hooks 改写文件时，重新审查受影响的差异并完成必要验证，再继续提交。

完成全部 commit 后，使用 `git status --short` 和 `git log --oneline -n <count>` 核对结果，报告每个 commit 的 hash、标题和剩余修改。push、创建 PR、发布及其他外部操作仅在用户明确要求时执行。
