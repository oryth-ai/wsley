# Profile 与编译器分析

## 选择采样类型

| 证据 | 解释什么 | 判断边界 |
| --- | --- | --- |
| CPU profile | 采样期间执行 CPU 工作的调用栈 | 不直接度量 I/O 等待或完整请求延迟 |
| `alloc_objects` / `alloc_space` | 累计分配对象数 / 字节数 | 关注分配速率与 GC 压力，不等于当前存活对象 |
| `inuse_objects` / `inuse_space` | 采样反映的存活对象数 / 字节数 | 需要结合负载、GC 时机和多次观察，不能凭一次快照认定泄漏 |
| Goroutine profile | 取样时各 goroutine 的堆栈 | 单次阻塞栈只提供位置，不能独立证明泄漏或耗时 |
| Block profile | 已采样的同步阻塞成本 | 需要启用，且不覆盖所有外部 I/O 等待 |
| Mutex profile | 锁竞争相关的累计等待成本 | 可归因到持锁者的解锁栈，不应将每个热点理解为当前等待者 |
| Execution trace | 调度、GC、同步、系统调用等事件的时间关系 | 采集有开销且数据可能很大，限定窗口与用途 |

## 从基准采集

以下示例限定一个包，`task_dir` 使用任务目录的绝对路径。性能比较的计时运行不同时启用这些诊断选项。

```bash
go test -run '^$' -bench '^BenchmarkParse$' -benchtime 3s -cpuprofile cpu.pprof -outputdir "$task_dir" -o "$task_dir/cpu-package.test" ./path/to/package
go tool pprof -top "$task_dir/cpu-package.test" "$task_dir/cpu.pprof"
go tool pprof -top -cum "$task_dir/cpu-package.test" "$task_dir/cpu.pprof"
```

内存采样可用同样的包与基准，将诊断选项替换为 `-memprofile memory.pprof`，并为其指定独立的 `-o` 路径；用 `-sample_index=alloc_space`、`alloc_objects` 或 `inuse_space` 选择实际需要的指标。

CPU、memory、block、mutex 等采样选项可能保留测试二进制。显式使用 `-o` 和 `-outputdir` 避免生成物散落源码目录，保留与 profile 完全匹配的二进制及源码版本，不用重新编译后的程序解释旧样本。

先用 `-top` 看 flat 成本，再用 `-top -cum` 看累计调用成本；通过 `-list '<function-regexp>'` 回到具体源码，核对输入和调用链。累计百分比可能重叠，不能相加当作总耗时；过滤结果和相对百分比也不等于整个服务的成本。

## 等待与时序

需要分析执行时序时，可用 `go test` 的 `-trace "$task_dir/trace.out"` 采集，再执行 `go tool trace "$task_dir/trace.out"`。界面绑定在本机，窗口长度按问题及资源预算选择，不默认长时间捕获。

区分 running、runnable、同步阻塞、网络等待与系统调用。CPU 饱和、调度延迟和外部服务慢需要不同修正；一个 goroutine 数量或平均 CPU 指标不能代替因果分析。

Block 和 mutex profile 在进程中需要相应的采样设置，基准可使用 `-blockprofile`、`-mutexprofile` 及对应采样参数。调整采样率前确认开销，结束后恢复本任务的诊断设置；不以永久全量采样作为默认运行方式。

## 线上证据

使用项目已有、受限且获授权的诊断入口。采集 CPU profile 时指定时间预算，堆、goroutine 和 trace 按用途分开；不为调研把调试端点绑定到公网，也不读取或外传任务外数据。

复用已有请求追踪和运行指标，区分 Go runtime 指标、Prometheus 实际暴露的指标与进程 RSS。检查真实名称、标签、单位和时间窗口，不从技能示例推导某条指标一定存在；长期遥测采用 [observability-and-instrumentation](../../observability-and-instrumentation/SKILL.md)。

## 编译器依据

分配或内联结果异常时，用项目实际构建选项配合 `-gcflags='-m=2'` 查看逃逸与内联决定，输出保存到任务目录。必要时查看限定函数的 SSA 或匹配二进制的汇编；SSA、汇编和编译日志的路径也要显式指定或在任务目录中生成。

编译器诊断解释某个版本和构建条件下的决定，不能仅凭“逃逸到堆”认定缺陷，也不能凭源码语法断言 SIMD、内联或零分配已经发生。优化收益仍由相同条件下的基准和实际用例证明。
