---
name: shadcn
description: Find, inspect, integrate, compose and update shadcn/ui components and blocks using official website examples, registry source and project-aware CLI commands. Use when implementing or debugging UI in a shadcn project, or when shadcn is requested. Preserve the actual framework, base library and local customizations.
---

# shadcn/ui

将 shadcn/ui 官网的真实示例、registry 源码与项目实际组件连起来，按当前任务查找、引入、组合、定制或修正组件。项目中的组件源码、配置和调用方共同确定实际契约，不能仅凭组件名称或模型记忆编写 API。

界面整体设计与实现采用 [frontend-design](../frontend-design/SKILL.md)，本技能负责 shadcn 的项目识别、资源发现与组件集成。任务仅涉及组件或只读诊断时直接处理对应范围，不额外启动视觉探索或整站审计。

## 项目与范围

读取所属应用的 `package.json`、锁文件、`components.json`、路径别名、主题入口、本地 UI 目录和相关调用方，确认框架、包管理器、Tailwind、基础组件库、样式、图标及已有定制。共享 UI 包与消费应用分别定位，不假设都使用 `@/components/ui`。

使用 [项目与 CLI](references/integration.md) 取得必要的项目上下文，已有信息仍有效时直接复用。`components.json` 缺失或字段不足时结合本地源码和依赖判断，不能为读取配置自动初始化项目或把旧项目升级为官网当前组合。

项目已经采用、用户明确要求或任务已确定选择 shadcn 时使用其实现流程。其他框架和组件体系保持原有选择；初始化、切换主题或基础库、批量更新只在当前目标确实涵盖时执行。

## 官网与源码

需要查找组件、页面组合或视觉参照时读取 [官网与发现](references/discovery.md)。先确定实际缺口，再选择 Components、Blocks、Charts 等入口，查看相应渲染和交互；已经明确的组件和未变化的证据直接复用，不逐次浏览首页或搜索整个 registry。

读取组件文档及实际实现，区分用法示例、组件源码和区块依赖。需要源码时按项目配置通过 CLI 解析官方 registry，官网的 View Code、Code 与文件树用于核对对应实现；更新与本地差异采用 CLI 的预览和比较能力。

当前官网可能采用不同的基础库或新版本 API。先选择匹配项目的文档与示例，再按 [组件契约](references/components.md) 检查组合、行为和主题，不将官网默认选项当作项目事实。

## 引入与修改

已有组件优先使用本地实现与有效变体。缺少必要组件或需要上游更新时，按项目与 CLI 中的流程预览文件、依赖和样式变化，读取实际差异后执行必要修改；本地定制与调用方同步保留，不用批量覆盖代替合并。

区块沿实际文件清单集成子组件、hooks、工具、样式和资源，统一项目别名、图标、路由、数据与本地化。演示中的数字、人物、导航和模拟提交根据真实任务调整，下载区块不代表相关业务已接入。

主题通过项目实际变量、组件变体与共用样式维护。需要改变组件源码时在负责该行为的位置修改并核对调用方，不通过一层层页面覆盖掩盖状态或样式冲突。

## 验证与交付

按组件契约和项目要求完成必要的静态及行为验证，涉及画面与交互时采用 frontend-design 的 [验证与交付](../frontend-design/references/verification.md)。已有专项结果直接承接，不因新增组件重复启动完整审计。

交付所请求的实现或诊断，说明采用的示例与来源、保留的项目选择、实际验证及缺口。工程修改遵循 [disciplined-dev](../disciplined-dev/SKILL.md)，浏览与素材使用遵循当前授权，保留适用许可和来源声明。
