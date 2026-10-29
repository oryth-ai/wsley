---
name: golang-performance
description: Review and optimize Go hot paths using evidence about allocations, CPU, memory layout, garbage collection, I/O and caching. Use after a measured bottleneck or for an explicitly requested performance code review. Use golang-benchmark for measurement and profile interpretation; preserve business, concurrency and resource-lifecycle guarantees.
---

# Go Performance

针对已证实的成本选择优化方式，保持行为、资源责任和可维护性。修改遵循 [disciplined-dev](../disciplined-dev/SKILL.md)，测量采用 [golang-benchmark](../golang-benchmark/SKILL.md)，不把某种实现模式当作所有 Go 代码的默认要求。

## 范围与依据

确认目标场景、指标、支持的 Go 版本、已有 profile 和基准。先区分进程内 CPU、分配、锁、调度及外部数据库、网络或存储等待，再选择负责该成本的部分；外部等待占主导时，不用局部循环优化宣称解决完整延迟。

用户只要求性能审查时，交付具体调用链、可疑成本、假设及需要的测量。未测量的问题可作为候选，不能编造收益或直接定性为瓶颈；用户已经要求优化时，补齐必要基线后实施，不重复索要已明确范围内的授权。

## 选择改法

| 已确认的成本 | 采用的方法 |
| --- | --- |
| 分配频繁、对象滞留、布局或局部性成本 | [内存与 CPU](references/memory-and-cpu.md)，核对所有权、逃逸、容量与实际访问模式 |
| 算法复杂度、重复解析、重复查询或计算 | [算法与缓存](references/algorithms-and-caching.md)，先消除无用工作，再评估缓存与失效成本 |
| 连接、缓冲、序列化、批处理或外部等待 | [运行时与 I/O](references/runtime-and-io.md)，保持协议、超时、顺序与失败语义 |
| GC、内存配额、CPU 配额或 PGO | 同一资料中的运行时方法，按实际工具链与部署条件测量 |
| 锁竞争、goroutine 失控或取消开销 | [golang-concurrency](../golang-concurrency/SKILL.md)，先明确并发与退出责任 |
| PostgreSQL 查询与事务占主导 | [supabase-postgres-best-practices](../supabase-postgres-best-practices/SKILL.md)，从真实计划与锁证据优化 |

## 实施与验证

一次修改检验一个清楚的假设，先考虑减少重复工作、改进算法和数据访问，再考虑更复杂的池化、缓存、并发或底层技巧。收益与复杂度一并评估，不用固定倍数或百分比为某种改法提供通用依据。

核对输入、输出、错误、顺序、精度、身份与缓存隔离。池化和复用保留对象所有权，批处理保留事务与部分失败语义，延后执行保留取消和持久责任；不能用删除校验、放宽权限或伪造成功换取基准优势。

按相同条件重新测量，并使用 [golang-testing](../golang-testing/SKILL.md) 验证相关行为。对并发、池化和共享状态变化补充必要的竞争及退出验证；race、profile 或覆盖率检测的运行结果不直接用于正常性能对比。

比较吞吐、延迟、内存、CPU 和资源上限中受影响的指标，说明收益、代价与无显著变化。微基准有效时仍按目标核对真实调用路径，不将更快的单个函数表述为整个服务已改善。

## 交付

说明瓶颈依据、具体改法、测量条件、前后结果和保留的保证。证据不足时限定结论，未验证的优化假设保持为假设，不承诺固定提速倍数。

性能材料、临时基准和 profile 遵循项目的产物及清理规则；是否保留长期基准由持续回归价值决定。提交、推送、CI 接入与生产配置变更按当前请求执行，不从性能任务自动推导这些操作。
