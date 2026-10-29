---
name: python-performance-optimization
description: Profile and optimize Python CPU, memory and I/O costs using representative workloads and repeatable comparisons. Use for slow Python code, retained memory, expensive data processing or an explicit performance review. Use fastapi-expert for request lifecycles and database boundaries; do not infer application gains from isolated microbenchmarks.
---

# Python Performance Optimization

从真实工作负载定位 Python 性能成本，再选择有证据支持的改法。采用项目已有解释器、依赖、运行和测试入口，修改遵循 [disciplined-dev](../disciplined-dev/SKILL.md)，不为套用示例更换框架或升级运行时。

## 问题与依据

明确关注的是响应时间、吞吐、CPU、峰值内存、持续增长还是外部等待，记录输入规模、并发、缓存状态和资源限制。先复用已有 profile、请求追踪和运行指标，区分 Python 执行、原生库、数据库、网络及排队成本。

确认实际 Python 实现、版本、构建、依赖与部署方式。同一 Python 版本的普通与 free-threaded 构建也可能具有不同的成本和并发行为，不能仅凭版本号推定 GIL、线程收益或包兼容性。

用户要求代码审查时，给出具体调用链、成本假设和所需证据。已经要求优化时，补齐必要基线后实施；未测量的可疑模式不直接定性为瓶颈，也不编造提速倍数。

## 选择方法

| 当前问题 | 采用的方法 |
| --- | --- |
| 耗时集中在哪里，修改是否有效 | [测量与归因](references/measurement.md)，区分诊断 profile 与计时比较 |
| 内存峰值、对象滞留或 RSS 持续增加 | 同一资料中的内存方法，区分 Python 分配、原生分配与进程资源 |
| 算法、缓存、数据布局、并发或 I/O 成本 | [优化与取舍](references/optimization.md)，按已确认热点选择改法 |
| FastAPI 请求、异步依赖、序列化或事务 | [fastapi-expert](../fastapi-expert/SKILL.md)，保持请求与资源边界 |
| PostgreSQL 查询、锁与连接等待占主导 | [supabase-postgres-best-practices](../supabase-postgres-best-practices/SKILL.md)，使用真实查询与事务证据 |
| 线上缺少可关联的运行证据 | [observability-and-instrumentation](../observability-and-instrumentation/SKILL.md)，复用项目遥测设施 |

## 实施与验证

先减少重复工作、无效查询、额外复制和不合适的算法，再评估缓存、批量、并发或原生实现。一次比较检验清楚的假设，计入初始化、转换、失效及资源占用中属于实际操作的成本。

保持输入输出、顺序、精度、异常、身份、事务和取消语义。异步不等于 CPU 并行，批量不能擅自改变提交单位，缓存不能跨越数据所属范围或掩盖失效责任。

在相同条件下重复测量，保留原始样本和波动，结合行为验证判断收益与代价。共享硬件或服务上的候选依次测量，不把 profile、覆盖率或调试开销混入正常运行对比；微基准结论仍需对应实际调用路径。

使用项目已有诊断和比较工具。缺少可选工具时先用现有能力缩小问题，并说明证据边界；工具获取遵循项目依赖管理，不默认全局安装、切换解释器或调整宿主资源。

## 交付

说明瓶颈依据、具体改法、运行条件、前后指标和行为验证，区分已证实改善、无显著变化、环境噪声与尚待验证的假设。局部计算更快不代表完整服务容量或用户体验已经改善。

Profile、内存快照和临时基准遵循项目材料与清理规则。线上采样采用授权进程和已有入口，控制时间及开销；是否保留长期基准由持续回归价值决定，不从性能任务推导提交、发布或生产配置变更。
