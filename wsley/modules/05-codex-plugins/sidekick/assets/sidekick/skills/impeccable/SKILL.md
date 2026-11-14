---
name: impeccable
description: Design, implement and refine distinctive Web interfaces. Use for frontend builds, art direction, visual redesigns, reference reproduction, layout, typography, color, imagery, motion, UI polish, or making a generic or AI-looking interface more expressive. Covers exploration through project integration and rendered verification. Use frontend-audit for independent reviews and interface-analysis to explain existing implementations.
---

# Impeccable

把产品内容、视觉方向和真实交互组织成有辨识度、完成度与使用价值的 Web 界面。承担从方向探索到项目实现、现有界面精修与实际验证的完整设计工作；用户可以自然描述目标，无须选择上游命令或逐个调用技能。

设计方法在本目录维护，来源包括 Impeccable 的 Web 设计与精修方法，适用许可和改编来源见 `LICENSE`。本技能直接使用这些资料及 Sidekick 的浏览器能力，不依赖上游 CLI、检测器、hooks 或其设计状态文件。

## 确定设计任务

读取需求、真实内容、代表页面、品牌、设计变量、资源及相关组件，确认使用者、主要任务、交付范围和必须保留的行为。核对实际框架、路由、组件体系、样式入口与支持环境。已有方向可以存在于页面、组件和素材中，缺少设计文档不表示可以重新定义品牌。

| 当前任务 | 工作方式 |
| --- | --- |
| 新建页面、应用，或明确要求重新设计 | 按 [方向与构思](references/art-direction.md) 确定视觉与结构，再实现完整代表页面或关键流程 |
| 探索方案、比较方向，暂不实现 | 用实际内容呈现有意义的差异与取舍，交付到用户要求的深度 |
| 精修、增强表现力、去模板化或“去 AI 味” | 按 [精修与强化](references/interface-refinement.md) 改善现有方向，定位具体表现与共同原因 |
| 还原设计稿、截图或参考页面 | 按 [参考与设计还原](references/design-reproduction.md) 区分已知约束、实测与重建假设 |
| 明确的局部布局、字体、颜色或动效修改 | 直接读取对应资料并实施，沿用已确认决定 |
| 只评审现状、指出问题或检查变更 | 采用 [frontend-audit](../frontend-audit/SKILL.md)，交付发现与建议 |

已有明确方案时直接工作。只有缺失的信息会实质改变产品含义、品牌或交付范围时才澄清；不默认安排问卷、多方案评选、设计批准或新增项目文档。精修保留既有视觉身份，重设计按用户授权替换视觉方案，两者都保留有效产品事实与行为。

## 让方向成为画面

将“高级”“有冲击力”“更专业”等要求转成可以看到的决定：什么内容占据主位、眼睛沿什么顺序移动、疏密如何变化、字体如何发声、颜色和素材在哪里形成记忆点。用简短说明明确页面的构图、视觉重点和实现后果，再把它们落实到实际内容与组件中。

按当前页面目的分配表现力。营销页面需要价值、证据和行动路径，工作界面需要清楚的工作区、状态和高效操作，阅读页面需要连续阅读与定位，展示体验让作品和探索本身成为主角。同一产品的不同页面可以有不同重心，不将所有页面做成营销首屏，也不把工作界面的克制理解为灰色表格与文字堆放。

建立鲜明的主次关系与产品性格。主图、真实产品演示、排版构图、领域图形、色彩区域或关键交互都可以承担视觉重点，选择适合内容的手段并完整实现。空间、字体、图像、颜色和运动共同服务于方向；移除无效装饰后，仍应有值得看的主体和明确的阅读节奏。

按实际需要读取方法，不为普通局部修改加载全部资料：

| 设计问题 | 采用的方法 |
| --- | --- |
| 方向、页面目的、视觉主题、参考来源与方案比较 | [方向与构思](references/art-direction.md) |
| 构图、信息载体、分组、疏密与响应式 | [布局与空间](references/layout.md) |
| 字体性格、层级、行长、换行与混排 | [排版](references/typography.md) |
| 主色分配、语义色、主题与对比 | [色彩与主题](references/color-and-theme.md) |
| 主图、摄影、插画、产品画面与资源交付 | [图像与材料](references/imagery.md) |
| 表面、层次、图标、动效与交互质感 | [表面与动效](references/motion-and-surfaces.md) |
| 精修、强化、降噪与产品辨识度 | [精修与强化](references/interface-refinement.md) |

## 接入实际项目

按 [组件与实现依据](references/components.md) 读取本地组件、真实 API、变体和调用方。组件体系提供行为和基础材料，页面仍需形成自己的组合、构图与内容层级。项目采用或任务选择 shadcn/ui 时，使用 [shadcn](../shadcn/SKILL.md) 查找官网效果、registry 源码与匹配接口；其他体系采用其自身资源。

将设计接入真实路由、数据、表单、权限和状态。共用规则进入有真实消费者的设计系统，应用持有业务流程；具体修改采用 [disciplined-dev](../disciplined-dev/SKILL.md)。需要扩展组件或设计角色时在正确归属内完整实现，不用复制组件、叠加覆盖或模拟成功掩盖缺口。

使用真实或明确标识的示例内容，保留对象、单位、精度、时间范围及结果含义。文案和本地化问题分别采用 [ux-copy](../ux-copy/SKILL.md) 与 [i18n-expert](../i18n-expert/SKILL.md)。按 [组件状态与压力验证](references/component-states.md) 实现适用的加载、空结果、失败、处理中、结果未知、完成及恢复状态；首屏精致不代表整个流程完成。

## 验证完成度

按 [验证与交付](references/verification.md) 查看实际渲染与操作，同时判断产品任务、选定方向和实现质量是否成立。检查完整页面与关键状态，先核对构图、主体、层级和真实内容，再校准局部细节；代码结构正确、组件库成熟和截图存在都不能证明视觉目标已经实现。

修正有实际依据的差距，复用仍有效的证据。任务阻断与访问问题需要解决，方向的表现力也需要在最终画面中保留，不能以所有检查通过代替设计完成。交付实际界面或用户要求的方案、主要设计决定、验证范围和真实缺口，区分原型、示例与生产接入。
