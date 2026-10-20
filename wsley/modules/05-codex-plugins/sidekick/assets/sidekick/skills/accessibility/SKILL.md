---
name: accessibility
description: Review and improve keyboard access, focus, semantics, accessible names, contrast, forms and assistive-technology behavior. Use for accessibility tasks and concrete access barriers. Combine rendered evidence with manual interaction; automated scores do not prove conformance.
---

# Accessibility

让使用者通过不同输入方式和辅助技术完成实际任务。采用项目确定的支持范围和可访问性目标，按具体障碍选择验证，不从技能本身推导法律适用范围或默认认证承诺。

## 依据与证据

读取相关界面、组件和项目要求，确认目标任务、状态、设备与允许的审查或修正范围。可运行时先检查渲染后的可访问树、控件名称、角色和状态，再使用键盘走通流程。

现有 axe、Lighthouse 等工具用于定位可检测的问题，保留具体节点和结果；工具不可用时继续适用的手工检查，不为审计默认安装全套工具。完整覆盖需要人工验证，自动扫描满分不能证明符合全部 WCAG 要求。

## 检查与修正

按 [访问与交互模式](references/interaction.md) 检查语义、键盘、焦点、表单、动态通知及视觉条件。优先复用正确的原生元素；只有原生语义不能表达实际交互时才使用相应 ARIA 模式。

| 方面 | 需要核对的结果 |
| --- | --- |
| 感知 | 图片、图表、音视频及颜色信息具有适用的等价表达，文本可读 |
| 操作 | 任务可通过键盘、触摸等目标输入方式完成，焦点可见且不会失去出口 |
| 理解 | 标签、错误、帮助和认证流程可理解，输入与导航行为可预测 |
| 兼容 | 语义、名称、角色和状态能被目标辅助技术正确识别 |

按真实任务影响安排修复，不能只凭问题类型给所有页面固定严重级别。共享组件的修正核对调用方和全部相关状态；修改遵循 [disciplined-dev](../disciplined-dev/SKILL.md)。

## 验证与交付

修改稳定后重复相同的自动检查和手工任务，覆盖键盘进出、激活、关闭、错误与恢复。按目标核对缩放、窄屏重排、高对比度和减少动态效果；读屏行为使用真实辅助技术验证，不能用 DOM 属性推断已经通过。

交付障碍、触发步骤、节点或代码位置、实际影响和修复证据。说明所用浏览器、输入方式、辅助技术及未覆盖范围，视觉检查与交互证据分别表述。
