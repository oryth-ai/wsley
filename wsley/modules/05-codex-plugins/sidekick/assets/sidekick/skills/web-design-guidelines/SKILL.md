---
name: web-design-guidelines
description: Review web interface implementation for semantic controls, form behavior, navigation, responsive layout, resource loading and state feedback. Use for focused UI implementation reviews; use frontend-audit for a broader product and experience audit.
---

# Web Design Guidelines

从真实页面和对应源码检查 Web 界面的实现质量，将问题连接到使用者的任务与具体触发条件。整体产品、信息架构和体验审计由 [frontend-audit](../frontend-audit/SKILL.md) 组织，本技能负责实现层面的检查。

## 范围与证据

依据当前请求确定页面、组件和只读或整改模式，复用项目的设计系统、浏览器支持范围与已确认方向。已给出对象时直接检查，不为套用流程再次索要文件模式。

可运行时检查实际渲染、状态和交互，再沿组件与资源定位源码。无法运行时限定为源码审查，不把静态模式匹配写成已观察到的用户故障。按受影响部分读取 [实现检查](references/implementation.md)。

## 检查顺序

先处理无法完成操作、错误结果、键盘障碍、状态丢失和内容不可读，再处理布局、资源和细节。框架习惯、浏览器能力与产品规则按实际版本核对，不把某个站点的视觉约定当作通用规范。

语义、焦点与辅助技术的问题使用 [accessibility](../accessibility/SKILL.md)，文案和语言资源分别衔接 [ux-copy](../ux-copy/SKILL.md) 与 [i18n-expert](../i18n-expert/SKILL.md)，React 性能问题使用 [vercel-react-best-practices](../vercel-react-best-practices/SKILL.md)。只加载当前问题需要的部分。

## 修正与交付

每项发现说明位置、触发状态、观察结果、影响与建议。修复共用组件时核对调用方和所有受影响状态，保留已有风格与业务契约；修改遵循 [disciplined-dev](../disciplined-dev/SKILL.md)。

集中验证受影响的布局、交互、键盘和资源加载行为，交付实际发现与证据。没有明确标准时不机械打分，也不把一次自动扫描当作完整体验验收。
