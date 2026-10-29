---
name: golang-benchmark
description: Measure Go performance with representative benchmarks, pprof, execution traces and statistical comparisons. Use to locate CPU, allocation, memory, blocking or scheduling costs, compare optimization candidates, or investigate benchmark regressions. Use golang-performance to choose and implement optimizations after measurement.
---

# Go Benchmarking

把性能疑问转为可复现的测量，区分成本发生在哪里、为什么发生，以及修改是否产生实际收益。采用项目的 Go 工具链、benchmark 布局和运行入口，修改遵循 [disciplined-dev](../disciplined-dev/SKILL.md)。

## 问题与基线

明确关注的是延迟、吞吐、CPU、分配量、存活内存还是资源等待，记录具体场景、输入规模、并发、缓存状态和目标。先复用已有测量及真实负载证据，不用微基准代替服务容量或用户体验结论。

固定比较双方的工具链、依赖、构建选项、硬件与资源限制。基线和候选使用同一组能代表实际工作的输入；夹具、算法、工具链或机器同时变化时，分别解释影响，不把结果全部归因于代码优化。

## 选择测量

| 问题 | 采用的证据 |
| --- | --- |
| 函数或用例的时间、吞吐和分配是否变化 | [基准与比较](references/measurement.md)，构造有效夹具并比较重复样本 |
| CPU 时间、分配和存活对象集中在哪里 | [Profile 与编译器分析](references/profiling.md)，核对采样类型、调用链及匹配的二进制 |
| 低 CPU 下仍有长延迟，或存在调度、GC、锁和 I/O 等待 | 同一资料中的 block、mutex 与 execution trace 方法 |
| 线上表现与本地基准不一致 | 结合真实请求、输入分布和已有遥测，采用 [observability-and-instrumentation](../observability-and-instrumentation/SKILL.md) 核对观测语义 |

测量方法按问题选择，不默认同时开启所有 profile、race、覆盖率和 trace。诊断运行与用于前后对比的计时运行分别组织，采样和检测开销不能混入未经说明的性能结论。

## 执行与比较

一次比较针对一个明确假设。先核对夹具、断言、对象重置和计时边界，再运行限定包与限定 benchmark；通用行为和并发正确性采用 [golang-testing](../golang-testing/SKILL.md)。

重复采样并按实际噪声、成本和目标确定预算。共享 CPU、内存、磁盘或服务上的比较串行测量，不让多个候选互相争用资源；不同代码目录不代表硬件已经隔离。保留原始样本，说明异常值的处理，不反复运行直到得到期望结果。

优先使用项目已有的 benchstat 或比较入口。缺少统计工具时仍可采集基线和分析 profile，但不能把人工挑选的单次结果当作统计显著的改善；工具安装沿用项目工具管理方式，不由本技能默认全局安装或升级。

线上采样只在授权环境和已有诊断入口进行，明确时间、采样率及资源预算。Profile、堆栈和 trace 可能含业务数据，按项目材料规则保存，不因诊断而公开 pprof 端点或上传原始数据。

## 结论与衔接

交付测量入口、版本与资源条件、原始指标、分布或区间，以及能支持的结论。区分未发现差异、样本不足、环境噪声和实际回归；没有显著差异不证明两个实现等价。

定位到热点后，采用 [golang-performance](../golang-performance/SKILL.md) 选择修正；只要求分析时交付证据，不自动修改实现、接入 CI 或创建提交。已有 CI 需要性能门槛时，依据稳定基线、实际预算和噪声设置规则，不复制统一百分比阈值。
