---
name: supabase-postgres-best-practices
description: Design and review PostgreSQL schemas, queries, transactions, locking, connections and row-level security. Use for database correctness and measured performance work. Apply to PostgreSQL wherever hosted; Supabase-specific features require actual project use.
---

# PostgreSQL Engineering

结合业务不变量、实际 PostgreSQL 版本和真实查询证据设计数据库行为。适用于自管和托管 PostgreSQL，Supabase 的身份函数、连接模式和平台配置只在项目实际采用时使用。

## 契约与结构

读取权威 schema、迁移或声明式定义、调用方与项目初始化流程，确认事实拥有者、约束、支持范围和变更入口。既有查询用于核对现状，不能仅凭实现推翻已确认的业务模型。

按 [结构与并发](references/schema-and-concurrency.md) 设计类型、键、约束、权限和事务。初始化、迁移、恢复及普通运行分别遵循项目契约；不自动增加历史版本兼容或在启动时修补 schema。

## 查询与资源

取得实际查询、参数分布、数据规模、索引和计划，区分扫描、估算偏差、锁等待、连接不足、I/O 与 CPU 问题。按 [查询与运行](references/queries-and-operations.md) 选择索引、连接和访问策略，不根据列名或固定速度倍数判断收益。

`EXPLAIN ANALYZE` 会执行语句，写查询或昂贵查询的验证需要合适环境与授权。对生产数据采用项目允许的只读、采样和预算，不能把收集证据扩大为执行写入或重建数据。

## 安全与高级能力

权限与 RLS 基于真实调用角色和会话上下文验证，服务角色、表拥有者和普通客户分别检查。应用层隐藏、筛选或登录成功不证明行级隔离；索引优化不能绕过策略。

全文检索、JSONB、分区、触发器、函数、向量、队列和定时任务按当前用例及实际扩展能力选择。扩展并非默认依赖，副作用、并发和持久恢复责任仍由明确边界承担。

## 验证与交付

使用真实 PostgreSQL 验证约束、提交可见性、事务回滚、权限和并发更新。涉及 FastAPI 异步会话时衔接 [fastapi-expert](../fastapi-expert/SKILL.md)，涉及原操作与状态机时衔接 [domain-modeling](../domain-modeling/SKILL.md)。

修改遵循 [disciplined-dev](../disciplined-dev/SKILL.md)，同步权威输入、调用方、生成物与必要验证。交付行为变化、测量条件、实际计划和限制，不用纯 mock 或示例计划宣称数据库语义已经成立。
