---
name: vercel-react-best-practices
description: Diagnose and improve React and Next.js data loading, bundle size, rendering and interaction performance. Use for concrete performance work and reviews. Apply only APIs supported by the project and verify gains without changing identity, caching or business semantics.
---

# React Performance

从用户可见等待、资源成本和真实渲染行为定位 React 性能问题，再选择适合当前项目的改法。保留已确定的框架、路由、数据与状态架构，不把性能技巧当作所有组件的固定模板。

## 证据与优先级

读取项目 React、框架、构建和编译器版本，以及相关请求、组件与资源入口。先确认慢在网络瀑布、服务端计算、传输体积、客户端工作还是重复渲染，复用已有 profiler、请求与打包证据。

优先处理会阻断主要任务的串行等待与大体积资源，再处理有实际影响的服务端、渲染和 JavaScript 成本。测试条件和输入应能代表当前问题，不能凭代码行数或单次开发模式耗时宣布优化。

| 问题 | 读取资料 |
| --- | --- |
| 性能基线、Profiler、浏览器时间线与前后比较 | [测量与归因](references/measurement.md) |
| 请求瀑布、服务端边界、缓存与客户端包体 | [数据与资源](references/data-and-bundles.md) |
| 状态订阅、Effect、重渲染、hydration 与视觉更新 | [状态与渲染](references/state-and-rendering.md) |
| 浏览器监听、持久化、计算与微优化 | [客户端成本](references/client-costs.md) |

## 实施边界

缓存、并发和延迟执行必须保持身份、权限、事务、时效与原操作语义。服务端动作独立验证身份和对象授权，客户端边界和界面隐藏都不能替代服务端控制。

选用 React cache、Suspense、Transition、Effect Event、Activity 或框架扩展时核对项目实际版本与语义。依赖或编译器已经承担的工作不再重复手动包装，不为套用示例升级 React 或引入新的状态库。

修改遵循 [disciplined-dev](../disciplined-dev/SKILL.md)。界面层级、操作反馈和访问问题分别使用相应内部能力，不为减少重渲染删除用户需要的信息或改变交互结果。

## 验证与交付

在可比较的条件下验证请求顺序、资源大小、渲染或交互成本，并重走受影响的成功、失败和恢复路径。核对服务端与客户端身份变化、切换路由和重复操作，不把视觉上更快当作正确性证明。

交付瓶颈、具体改法、前后证据及限制。没有测量时说明实现了什么以及尚待验证的收益，不给未经支持的加速倍数。
