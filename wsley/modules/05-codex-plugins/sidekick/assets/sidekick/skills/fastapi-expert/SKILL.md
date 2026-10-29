---
name: fastapi-expert
description: Design, implement or review FastAPI services with validated contracts, explicit async lifecycles and database transaction ownership. Use for dependency injection, blocking I/O, async SQLAlchemy, response serialization, streaming and request performance. Preserve the project's identity protocol, stack and supported versions.
---

# FastAPI Expert

遵循项目实际 Python、FastAPI、Pydantic、数据库及测试版本，明确请求、用例、事务和资源生命周期。修改前读取并遵循 [disciplined-dev](../disciplined-dev/SKILL.md)，不根据示例另建应用目录、认证系统或通用 CRUD 层。

## 请求与契约

从现有路由追踪依赖、用例、数据及外部调用。用类型和输入模型表达边界约束，按契约处理未知字段、数值精度、时间和标识。响应模型显式限制可返回字段，禁止把 ORM 对象中的敏感或内部字段直接暴露给客户。

按项目支持的 API 使用 `Annotated` 表达参数与依赖约束，依赖负责装配、共享逻辑和资源收尾，Pydantic 负责适用的纯数据校验。路由、用例和模型按实际职责组织，不为每个依赖创建别名或固定层次。

HTTP 状态、稳定错误类别、命令身份、分页和 OpenAPI 与项目协议保持一致。区分输入无效、业务拒绝、依赖不可用和结果未知；不把提交后超时伪装为未执行。生成客户端从权威接口输入更新。

沿用实际支持的 Cookie、OIDC、令牌或服务凭据协议，分别验证身份、对象所属、动作与状态权限。不因框架提供示例而添加 JWT、改写会话期限或另建登录入口。

## 异步与生命周期

`async def` 不会使同步 I/O 自动异步。FastAPI 调度的普通 `def` 路由与依赖进入线程池，在异步函数中直接调用普通 helper 则不会。检查数据库、文件、SDK、模型与网络调用，使用项目已有异步接口；确需运行阻塞工作时，采用有界执行器或独立执行服务，明确并发、内存、截止时间及取消语义。

进程生命周期通过项目支持的 lifespan 入口显式建立并关闭连接池、客户端与执行器；导入模块和生成接口定义不得隐式连接依赖或启动任务。依赖装配沿用项目的显式入口，避免通过可变全局应用容器隐藏资源拥有者。`yield` 依赖的作用域和退出时机按实际版本核对，不默认在响应发出后才提交关键事务。

请求取消、超时与进程退出分别核验。取消协程不等于停止线程、模型执行或远程副作用，保留原操作身份与恢复责任。需要跨进程存活的任务采用项目持久任务机制，不依赖 `BackgroundTasks` 或未托管的 `create_task` 承担持久交付。

## 数据库与副作用

涉及数据库会话、事务或异步加载时，读取 [references/async-boundaries.md](references/async-boundaries.md)。事务由拥有完整用例的边界决定，不在每个 CRUD helper 中隐式提交。

同一事务内需要共同成立的记录和入队使用同一数据库会话。并发唯一性和数量限制由真实约束与事务保护；先查询不存在再插入不能独立证明并发安全。

网络、对象存储和支付等外部系统不属于本地事务。明确意图持久化、重试和结果确认的实际协议，不依赖异常捕获自动回滚已发生的外部行为。

## 性能与流式交付

涉及请求变慢、响应编码、吞吐、流式或 SSE 时，读取 [请求性能与流式边界](references/performance.md)，区分事件循环、线程与连接池、查询、序列化及传输成本。Python 热点的测量和优化采用 [python-performance-optimization](../python-performance-optimization/SKILL.md)，不以局部编码基准代替完整请求证据。

FastAPI、Pydantic、ASGI 服务器与项目的实际支持范围共同决定可用能力。采用框架支持的类型化响应路径，核对流式响应、依赖退出与断连收尾；不为套用最新示例替换数据库栈、调度库、认证协议或现有应用入口。

## 验证与交付

复用项目已有 pytest、异步 HTTP 客户端和真实依赖夹具。内存 ASGI 调用是否执行 lifespan 由实际客户端与夹具决定，需要启动资源时显式管理生命周期。依赖 override 在测试结束时恢复，不让共享应用对象污染后续场景。

验证输入、响应、权限、真实事务、重复命令、取消和资源收尾中受影响的行为。纯 ASGI 或 mock 测试不证明真实 TLS、代理、网络和进程部署正确；按变化补充对应交付验收。实现稳定后执行必要检查，避免每个路由修改后重复全量构建和测试。

交付最终接口与事务边界变化、实际验证和未覆盖范围。只有本次用例确实需要的文件与职责才进入实现，不为套用输出模板创建 schema、router、CRUD 的固定文件集合。
