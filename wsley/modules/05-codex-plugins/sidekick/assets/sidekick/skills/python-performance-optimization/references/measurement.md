# 测量与归因

## 工作负载与基线

先定义一次操作的输入、可观察结果、状态与完成条件。覆盖实际规模、数据分布和有关的成功或拒绝路径，分别处理冷启动、热缓存、初始化及稳态；不能用重复命中同一缓存的结果代表真实查询。

固定解释器、构建、依赖、硬件、进程数量、并发和资源限制。比较双方使用相同夹具，记录预热与缓存条件；数据库对象增长、输入被消费或前一次写入已完成，都可能使后续样本变成不同工作。

准备和清理是否计时取决于操作契约。变更需要的转换、索引构造、进程启动或序列化不能只在候选中移出计时范围。测量前在计时外验证结果，不能只确认函数成功返回。

## 时间与 profile

`time.perf_counter()` 测量经过时间，包含等待；`time.process_time()` 测量当前进程的 CPU 时间，不代表子进程成本或请求完整延迟。异步、线程与多进程的归因先确认工具覆盖的进程、线程和任务范围。

以下命令使用目标项目的 `python` 入口。`workload.py` 替换为可重复运行的实际工作负载，参数与运行次数按问题选择；`task_dir` 是项目允许的独立任务目录的绝对路径。

```bash
python -B -m cProfile -o "$task_dir/cpu.prof" workload.py
python -B - "$task_dir/cpu.prof" <<'PY'
import pstats
import sys

stats = pstats.Stats(sys.argv[1])
stats.sort_stats(pstats.SortKey.CUMULATIVE).print_stats(20)
stats.sort_stats(pstats.SortKey.TIME).print_stats(20)
PY
```

`cumtime` 包含子调用，`tottime` 反映函数自身；累计值可能重叠，不能相加当作总耗时。cProfile 是确定性调用分析，结果包含插桩开销，并非纯 CPU 采样；等待和协程切换也需要结合时间线解释。启动与导入成本是否代表长驻服务，取决于工作负载的实际生命周期。[Python profiler 文档](https://docs.python.org/3/library/profile.html)

项目已有 py-spy 或逐行分析器时，按其实际版本选择采样范围、原生栈和子进程支持。采样比例不直接等于请求延迟，不能从无样本证明没有成本；连接生产进程前核对授权与资源预算，不自行降低系统安全限制。

## 计时比较

短小同步计算可使用 `timeit`，完整用例优先沿用项目基准或负载入口。例如 `project.workload.run_once` 应替换为具有代表性的可重复操作：

```bash
python -B -m timeit -r 7 -n 200 -s 'from project.workload import run_once' 'run_once()'
```

次数不是统一标准，需覆盖有效计时长度及预算。`timeit` 的 setup 不计时且计时期间默认关闭循环 GC；输入每轮需要重置时明确安排，GC 属于真实成本时在 setup 中恢复，不能让一次性迭代器被首轮消耗后继续测空操作。[timeit 文档](https://docs.python.org/3/library/timeit.html)

保留重复样本与每次实际操作数，先核对单位和工作等价性，再判断差异。最短样本可以描述较少干扰下的成本，不能替代服务延迟分布；单次 `time.time()`、两个不等次数的总耗时或挑选最好结果都不足以证明改善。

项目已有 pyperf、pytest-benchmark 或其他比较工具时，沿用其预热、进程隔离、元数据和比较入口。检查波动、样本量及实际意义，不隐藏不稳定警告或循环运行直到显著；共享资源上的基线与候选依次运行，不自动执行系统调优命令。[pyperf 测量说明](https://pyperf.readthedocs.io/en/latest/run_benchmark.html)

## 内存与滞留

先区分瞬时峰值、稳态工作集与重复执行后的持续增长。RSS、容器用量、Python 活跃分配及分配器保留内存不是同一指标，解释器不立即向操作系统归还内存不能单独证明泄漏。

`tracemalloc` 从启用后追踪的内存块提供分配来源；部分原生库、设备和进程资源不在其覆盖内。尽早启用并核对插桩开销，快照反映当时仍存活的分配，`get_traced_memory()` 的峰值与前后快照回答不同问题。[tracemalloc 文档](https://docs.python.org/3/library/tracemalloc.html)

比较相同预热与生命周期位置的快照，针对重复用例查看 `compare_to()` 的大小和数量变化。保留结果是否属于真实契约需要一致；只在函数内创建、返回前已释放的临时列表，不能用返回后的快照演示持续泄漏。必要的 GC 控制对两侧一致，不把强制收集或关闭 GC 当作默认修复。

`sys.getsizeof()` 只给对象自身的浅层大小。实例字典、引用对象、数组缓冲和共享存储需按实际所有权计入，不用生成器与列表、普通类与 `__slots__` 的浅层大小直接推导完整内存收益。

快照、调用栈和 trace 可能含路径及业务数据，按项目材料规则保存。诊断完成后撤除临时插桩，按原条件重新测量时间、内存和受影响的完整行为。
