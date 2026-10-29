---
name: golang-testing
description: Write, review or debug Go tests that verify observable behavior, real dependency boundaries and concurrency. Use for meaningful coverage gaps, flaky tests, fuzzing and race or leak verification. Follow the project's existing test layout and runner; do not introduce tests solely for coverage targets.
---

# Go Testing

围绕调用者可观察的行为验证规则和失败语义，采用项目现有工具链、测试层次与资源约定。修改前遵循 [disciplined-dev](../disciplined-dev/SKILL.md)，读取被测实现、夹具与后置断言，明确新增证据和仍有效的已有证据。

## 选择验证边界

- 纯规则、计算和边界输入优先用原生单元测试
- SQL、约束、锁、持久队列及外部协议使用真实专用依赖验证
- goroutine、取消、超时和共享状态覆盖退出条件与竞争
- 具有不变量、往返关系或独立参考结果的输入域适合 fuzzing 或属性测试
- 性能疑问采用 [golang-benchmark](../golang-benchmark/SKILL.md) 进行有代表性的测量与比较，不能用单次测试耗时替代

沿用项目已有目录、包、命名、build tags 和执行入口，不强制单文件对应、统一测试包后缀或新增集成标签。所用标准库 API 依据项目实际 Go 版本核验，不为使用示例升级工具链或增加旧版适配分支。

## 编写与审查

多个并列场景适合 table-driven tests，并使用含义明确的 `t.Run` 名称；单一行为可直接测试。断言业务结果、错误类别和实际副作用，不复制被测算法作为预期值，不依赖私有调用顺序来替代契约验证。

每个子测试使用自己的 `*testing.T` 和断言实例，helper 调用 `t.Helper()`。阻止后续断言成立的准备错误立即终止当前场景，错误断言保留具体诊断信息。复用项目已采用的断言工具，不为简单比较新增依赖或安装脚手架生成器。

HTTP 测试核对协议状态、响应结构与业务状态的对应关系，以及认证、对象授权和副作用。状态码本身不足以证明命令正确完成。

## 并发与资源

并行仅用于资源、状态与生命周期互不影响的测试。共享时钟、进程环境、全局配置、端口、数据库和故障注入先明确隔离责任，不机械补充 `t.Parallel()`。

优先通过显式同步、可控时间和有界等待验证并发顺序，避免依赖任意 `Sleep`。真实网络与数据库操作也要有截止时间。核对 caller 取消、提前返回、依赖失败和进程收尾后 goroutine 是否退出；已有 race 或泄漏检测工具按其适用范围使用。

场景需要临时文件、进程和服务时，读取 [references/boundary-verification.md](references/boundary-verification.md)。清理失败保留必要诊断，不将自身未停止的写入者留给下一轮测试。

## 执行与结论

使用项目规定的最小充分验证集。先完成关联实现和夹具，再运行对应行为验收；新修改、失败或真实覆盖缺口才扩大范围。失败时区分产品缺陷、夹具错误、环境问题和并发不确定性，不通过盲目重试、放宽预算或跳过断言使测试通过。

原生 `go test` 的 `-run` 使用正则表达式，限定单个测试时使用锚点；race、fuzz 和 benchmark 分别说明实际参数及覆盖范围。覆盖率帮助定位遗漏，不作为正确性分数或新增无价值测试的理由。

交付被验证的行为、执行入口、实际结果与环境限制。单元或 mock 结果不替代真实依赖、镜像与完整恢复验收。
