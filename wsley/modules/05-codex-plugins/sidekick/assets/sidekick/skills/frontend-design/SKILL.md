---
name: frontend-design
description: Design and implement Web pages, applications and components with intentional visual choices, project components and rendered verification. Use for frontend builds, visual redesigns and reference reproduction. Use oil-ui to explore directions, interface-analysis to explain an existing effect, and frontend-audit to review a frontend.
---

# Frontend Design

将产品任务、视觉决定、组件源码和业务状态落实为有辨识度的 Web 界面。内容、排版、色彩、构图与交互共同表达产品，交付范围由用户需求和项目契约确定。

## 项目依据

读取需求、真实内容、代表页面、品牌、设计变量及相关组件，确认使用者、主要任务、交付物和必须保留的行为。核对消费应用的框架、路由、依赖版本、组件体系与样式入口，不从示例反推项目应采用的技术栈。

承接已确认的方向、参考和业务边界。具体改法明确时直接实施；只有会实质改变方案的产品或视觉缺口才需要澄清。外部网站用于理解机制时采用 [interface-analysis](../interface-analysis/SKILL.md)，设计稿和截图还原采用 [参考与设计还原](references/design-reproduction.md)。

## 页面与方向

先按任务区分集合、详情、编辑流程与阅读等页面类型，确定内容宽度、导航、主次操作和连续步骤如何承接。接口目录与内部模块用于核对能力，页面结构来自使用者的决策和操作；组件外观统一之后，仍需明确页面组合规则。

形成与任务规模相称的简短设计计划，说明内容优先级、布局、字体角色、色彩角色及关键取值、间距和视觉重点。已有决定直接承接，不重复索要批准或默认新增设计文档。需要探索尚未确定的方向时使用 [oil-ui](../oil-ui/SKILL.md)，把选定结果带入实现。

辨识度来自产品主题、内容、行业与材料。首屏可以由标题、图像、演示或交互建立识别；表格、字段、卡片和图表按信息关系选择。边框、标签与编号表达真实关系，折叠与浮层承载有价值的次要内容。常见风格只要适合需求即可采用，不固定套用同一模板，也不为新颖推翻用户选择。

## 视觉实现

按当前问题读取对应方法，不为普通局部修改加载整套资料：

| 实现需要 | 方法 |
| --- | --- |
| 字体、层级、行长、换行、数字或混排 | [排版](references/typography.md) |
| 语义色彩、主题、透明叠加与对比测量 | [色彩与主题](references/color-and-theme.md) |
| 表面、边框、阴影、圆角、动效与中断 | [表面与动效](references/motion-and-surfaces.md) |
| 设计稿、截图、资源与还原差异 | [参考与设计还原](references/design-reproduction.md) |

以内容决定空间。检查容器、网格轨道和子项的尺寸约束，必要时在负责收缩的 flex 子项使用 `min-width: 0`，或为需要收缩的网格轨道采用 `minmax(0, 1fr)`；先确认原因，避免全局覆盖。断点来自内容与容器实际失效的位置，固定尺寸用于确有尺寸契约的对象，不按单张截图绝对定位整页。

## 组件与业务接入

按 [组件与实现依据](references/components.md) 阅读本地组件和调用方，核对真实 API、状态与本地定制。缺少能力时再查找匹配版本的官方示例与源码，查看实际效果并取得相关实现。项目采用或任务已选择 shadcn/ui 时使用 [shadcn](../shadcn/SKILL.md)，其他体系使用其自身资源。

将结构和组件接入实际路由、数据、表单、权限与状态。共用规则归入有真实消费者的设计系统，应用持有业务流程；不以平行组件、反复覆盖选择器或包装层掩盖职责冲突。修改采用 [disciplined-dev](../disciplined-dev/SKILL.md)。

使用真实或明确标识的示例内容。文案表达对象、动作、结果和恢复方式，同一动作在按钮、等待与完成反馈中使用相同术语；缺少的业务事实不能用虚构客户、指标或承诺补齐。文案和本地化问题分别使用 [ux-copy](../ux-copy/SKILL.md) 与 [i18n-expert](../i18n-expert/SKILL.md)。

保留产品需要的加载、有效空结果、失败、处理中、结果未知、完成及恢复状态。按 [组件状态与压力验证](references/component-states.md) 组织真实分支、受控数据与边界内容；截图未展示的状态仍按业务契约实现，演示中的模拟行为不冒充真实能力。

## 验证与交付

实现稳定后按 [验证与交付](references/verification.md) 查看实际页面，验证目标视口、状态、受影响操作及项目必要检查。先修复任务阻断、阅读障碍、层级、裁切与对齐，再处理装饰细节。静态检查、截图文件存在和组件库来源都不能代替真实界面证据。

系统体验评审使用 [frontend-audit](../frontend-audit/SKILL.md)，聚焦实现和访问问题时采用相应专项能力，承接已有证据。交付最终界面、主要取舍、实际验证和具体缺口，区分原型、示例数据与真实接入；材料管理遵循项目约定。
