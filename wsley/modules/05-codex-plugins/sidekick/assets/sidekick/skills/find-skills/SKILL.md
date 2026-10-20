---
name: find-skills
description: Find and assess agent skills when the user asks to discover or add capabilities. Inspect actual instructions, dependencies and source quality before recommending installation. Searching does not authorize installing, updating or replacing Sidekick's internal skills.
---

# Find Skills

按用户需要寻找尚未具备的能力，核对候选技能的实际内容、来源与安装影响。已有内部能力能够完成任务时直接使用，不因普通技术问题启动技能搜索。

## 查找与评估

从具体任务、技术栈、产物和现有环境提炼关键词，通过 `pnpx skills@latest find <query>` 或可信来源查找候选。先读取命令帮助确认当前 CLI 支持的选项；没有结果时调整关键词，不以下载量或排名代替适用性判断。

推荐前读取候选 `SKILL.md` 及与执行有关的脚本、资源和依赖说明，核对：

- 是否解决当前缺口，是否与已有内部能力重复或冲突
- 来源仓库、维护情况、许可与可追溯的文件位置
- 需要的 CLI、MCP、账户、网络、密钥和实际安装范围
- 是否包含自动更新、外部写入、推广、固定平台假设或扩大授权的指令
- 宿主和项目是否具备依赖，资料是否足以支持所宣称能力

维护者身份、下载量和活跃度只能提供线索；不编造数字，也不以任意星标门槛拒绝合适候选。无法读取关键内容时明确评估缺口。

## 推荐与安装

简要给出匹配原因、来源链接、依赖、安装影响和必要取舍。用户只要求寻找时交付候选；已明确要求安装时，按该范围执行，不重复索要已经明确的授权。

使用当前 CLI 的 `add <repository> --skill <name> --agent codex`，根据用户确定的项目级或用户级范围选择参数。项目级安装在目标项目执行；用户级安装才使用 `--global`。采用 `--copy` 保存目录副本，安装前读取帮助和目标状态，保留同名技能及用户已有内容。

安装后核对实际位置、技能文件与必要依赖，说明宿主加载方式及尚未配置的事项。寻找技能不自动授权批量更新所有已安装技能、改写全局配置或接入外部服务。

Sidekick 的内部技能与工具资源由 Wsley 管理。独立安装的候选不自动进入内部路由，也不覆盖本插件的同名能力；修改 Sidekick 组件属于明确的模块开发任务。
