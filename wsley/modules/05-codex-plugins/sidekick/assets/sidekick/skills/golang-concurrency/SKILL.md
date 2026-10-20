---
name: golang-concurrency
description: Design and review Go goroutine ownership, cancellation, channels, synchronization, bounded workers and pipelines. Use for concurrent behavior, races, deadlocks or leaks. Preserve business invariants and verify that work can stop and be joined.
---

# Go Concurrency

明确并发工作的拥有者、共享状态和退出责任，再选择 goroutine、channel、锁或原子操作。同步实现足以满足需求时保留同步路径，不为套用模式增加并发。

## 调用链与生命周期

从入口追踪启动者、工作者、消费者、外部调用和停止流程。每项并发工作明确启动条件、结果交付、错误传播、取消方式和等待退出的拥有者。请求结束不代表后台工作已结束，发出取消也不代表远程副作用已停止。

审查现有问题时沿实际阻塞点、共享状态和故障证据定位，不局限于 diff 中的 `go` 语句。项目的 Go 版本和运行约束决定可用 API；不因上游示例引入新依赖、固定数量的子代理或未安装的其他技能。

## 选择同步方式

按 [同步与流水线](references/synchronization.md) 核对所选模式。

| 需要 | 常用方式 | 必须明确的边界 |
| --- | --- | --- |
| 交付值、传递所有权或协调阶段 | channel | 谁发送、谁接收、谁关闭以及取消后谁收尾 |
| 保护关联的共享字段 | Mutex 或 RWMutex | 所有访问使用同一保护规则，多字段不变量共同成立 |
| 简单独立计数或状态 | typed atomic | 原子单字段不等于整个业务操作原子 |
| 等待已启动工作结束 | WaitGroup | 计数与启动顺序、返回前的完整等待 |
| 收集错误并取消同组工作 | 项目已采用的 errgroup 等机制 | 并发上限、首个错误、剩余工作和外部副作用 |
| 合并相同键的并发请求 | 项目已有 singleflight 等机制 | 共享结果、取消、错误与缓存的不同语义 |

channel 传递指针或引用时仍可能共享可变状态，必须有明确的转移、不可变或同步约定；发送值也可能通过 slice、map 和内部指针共享底层对象。

## 资源与失败

对并发数、队列、内存、连接和等待设置有依据的边界，说明排队、拒绝与背压行为。缓冲区承担明确的容量或解耦职责，不能用于掩盖消费者退出和永久阻塞。

发送、接收和外部 I/O 在需要响应取消的路径上具有退出方式。关闭 channel 不代替等待，关闭方必须确认所有发送者已结束；不以 `recover` 掩盖竞争关闭。锁内避免不受控 I/O，跨资源加锁采用一致顺序。

并发实现仍需维护原操作身份、幂等性、事务和恢复责任。发生首个错误、调用者提前返回、消费者停止、超时或进程停止时，核对已经发生的副作用和未完成责任。

## 验证与交付

修改遵循 [disciplined-dev](../disciplined-dev/SKILL.md)，使用 [golang-testing](../golang-testing/SKILL.md) 验证调度、取消、竞争和退出。复用已有 race、profile 与泄漏检查，按项目版本核对工具能力，不因使用本技能安装整套检测工具。

交付并发边界、拥有者与停止方式，以及实际通过的场景和剩余限制。race 未报告问题不能证明所有业务并发顺序正确，goroutine 数量稳定也不能单独证明没有泄漏。
