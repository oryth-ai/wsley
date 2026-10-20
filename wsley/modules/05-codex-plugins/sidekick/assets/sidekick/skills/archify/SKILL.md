---
name: archify
description: Create validated standalone HTML diagrams and one-page explainers using the installed Archify renderer. Use for architecture, workflows, sequences, schemas, states and timing, including Mermaid input. Use draw.io instead when that editable format is required.
---

# Archify

把实际系统、流程或解释转为可探索的独立 HTML，使用随插件提供的 Archify schema、渲染器与验证工具。Sidekick 维护任务、输出位置和环境规则，工具资源只提供与实际版本匹配的技术契约。

## 选择表达

依据问题选择图表类型，读取 [类型与资源](references/types.md) 对应的 schema 和示例，再读取 [作者规则](../../vendor/archify/references/authoring-defaults.md)。真实代码图同时采用 [源码依据](../../vendor/archify/references/repository-authoring.md)，示例只说明形状，不能复制为项目事实。

用户明确需要一页解释时采用 [解释页](../../vendor/archify/references/explainer-authoring.md)，先给结论，再组织理由、范围及必要的图表。普通简短回答不自动生成页面，不主动修改全局规则以启用其他回复模式。

Mermaid 输入用于恢复节点、关系、顺序与状态含义，再按实际 schema 编写候选，不机械复制其样式。需要 `.drawio` 或 `.drawio.svg` 时使用 [next-ai-drawio](../next-ai-drawio/SKILL.md)。

## 生成与验证

本地工具目录为本文件对应的 `../../vendor/archify`。使用其 `bin/archify.mjs` 实际绝对路径，产物位置遵循项目约定；任务材料使用项目任务目录，不采用上游的固定 `.archify/` 目录。

普通原生图写出完整候选后直接执行 `finalize <type> <candidate.json> <output.html> --quality <profile> --json`。代码图加 `--repo-root <root>` 并保留实际依据，候选与命令的质量级别一致；密集 ERD 等内容按可读性选择合适级别。

通过 [运行环境](../mira/references/runtime.md) 设置已安装的 Chromium 路径，并关闭工具的独立更新检查。环境由 Wsley 准备，不在生成前重复执行安装、doctor 或演示初始化。

失败按 [交付契约](../../vendor/archify/references/delivery-contract.md) 定位对应 gate 并做有界修正，保留原问题、节点、关系和来源。已有 HTML 对应的浏览器证据与候选绑定，后续修正按工具要求使用独立证据目录，不能把旧回执用于新字节。

## 完成与交付

按通过回执说明自动校验结果，实际视觉查看与浏览器 gate 分别表述。用户要求视觉检查或发现具体布局问题时查看真实画面，不能因回执通过就声称已人工查看。

以可点击的 HTML 文件链接和必要结论交付，说明数据是否真实、重要抽象和未完成范围。工具包的目录默认值、更新推广和宿主全局配置流程不替代 Sidekick 的任务与维护规则。
