---
name: sre-engineer
description: Define service indicators and objectives, error budgets, capacity limits and recovery evidence. Use for reliability design, incident response, operational toil and resilience assessments. Use measured user impact and authorized environments rather than fixed targets or automatic production actions.
---

# Reliability Engineering

把用户可见的服务承诺连接到测量、容量、失败处理与恢复责任。沿用项目的运行设施和运维流程，不以某个可用性百分比、平台模板或固定人工负担比例替代实际目标。

## 服务目标

确认关键用户任务、成功与失败的业务含义、服务边界和已有承诺。按 [目标与容量](references/objectives.md) 定义 SLI、SLO、测量窗口、覆盖范围和错误预算，复用已确认目标；只有影响承诺的关键选择缺失时才澄清。

区分健康检查、请求成功、任务完成和最终业务交付。低流量、缺失遥测、异步积压和第三方责任分别处理，不能把没有样本记为百分之百可用。

## 诊断与改进

结合真实负载、队列、连接、CPU、内存、存储和外部延迟识别瓶颈，建立与目标相符的容量余量、并发、背压和扩展策略。性能优化通过代表性测量比较，不直接按峰值猜测重建架构。

遥测设计采用 [observability-and-instrumentation](../observability-and-instrumentation/SKILL.md)，本技能确定目标、告警条件与响应责任，不再重复完整的埋点评审。错误预算政策由项目定义，不能从示例自动推导冻结发布或停服决定。

## 故障与恢复

按 [故障与运行责任](references/recovery.md) 组织事故响应、恢复验证和重复劳动治理。区分提出演练方案、在隔离环境执行与变更生产系统；后者必须处于当前授权范围。

先控制用户影响并保留原操作身份、数据与证据，再定位原因。重试、重启、切流、降级和补偿都有实际业务后果，不用统一脚本自动替代项目恢复协议。

## 验证与交付

修改遵循 [disciplined-dev](../disciplined-dev/SKILL.md)。按当前变化验证故障注入、负载、停止、持久恢复及恢复后的业务一致性，复用已有真实环境；不把配置存在、容器健康或一次重启成功当作完整恢复证明。

交付目标与测量定义、实际瓶颈或风险、已实施改进及恢复证据。明确测试负载、窗口、环境和未验证的承诺，不凭一次演练宣称系统高可用。
