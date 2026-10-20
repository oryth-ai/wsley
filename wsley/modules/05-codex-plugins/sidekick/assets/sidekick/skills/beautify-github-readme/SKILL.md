---
name: beautify-github-readme
description: Design GitHub README homepages and project-specific SVG, raster or optional GIF assets. Use for README visual design and asset creation. Clarify whole-README versus asset-only scope when ambiguous, and confirm SVG versus hybrid composition when both meaningfully fit.
---

# README Design

让仓库首页以清楚的价值、真实证据和最短的首次使用路径介绍项目。Markdown 负责可阅读的内容，视觉资源表达产品身份与机制，不能把整页栅格化或用装饰替代事实。

## 模式与依据

区分完整 README 调整、仅制作资源和只读审计。请求范围不明确时确认对应模式；只制作资源时保持 README 内容、顺序与引用不变。用户已明确模式时直接沿该范围执行，不重复确认。

读取现有 README、产品输出、仓库结构、元数据和已有品牌资源，确定受众、实际价值、主要证据与首次成功动作。原始 URL 需要核对当前远端内容，不臆造下载量、性能、评价、兼容性或功能。

## 视觉选择

图表、代码、字标和几何表达优先使用可控 SVG，真实截图和既有项目资产优先于生成材料。大型主视觉同时适合纯 SVG 与混合合成时，先说明可编辑性、视觉表现、体积和制作成本的取舍并确认；用户明确选择或委派后按其决定执行。

混合合成让 SVG 承担准确排版，图像承担真实或生成的主体、材质和光线，通常发布经过验证的 PNG/WebP 并保留可编辑源层。GIF 仅在用户选择且运动有沟通作用时制作，同时保留静态 SVG，不把动画作为默认交付。

## 制作与结构

按 [内容与画布](references/canvas.md) 组织阅读顺序、字体、图片和 GitHub 可用的表现方式，使用 [资源与动效](references/assets.md) 处理 SVG、合成与 GIF。主题来自项目内容，不给所有仓库套用同一网格、配色或装饰。

完整 README 模式按目标选择重组或视觉更新，保留安装、使用、支持范围与必要许可信息。仅资源模式在项目认可的位置制作请求的资源，提供预览与可选嵌入片段，不自行写入 README。

## 验证与交付

使用已安装的 [agent-browser](../agent-browser/SKILL.md) 或现有渲染工具查看实际阅读宽度、窄屏、明暗背景、链接与资源，确认关键内容可读、图片无裁切、体积合适。不能用 SVG 语法通过代替视觉查看。

修改遵循 [disciplined-dev](../disciplined-dev/SKILL.md) 和明确文档授权。交付最终文件、预览、实际验证与限制；署名装饰、外部展示、提交、推送和发布只按用户请求执行，不在完成后自动加入推广或对外贡献流程。
