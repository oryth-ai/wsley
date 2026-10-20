# 类型与资源

下列路径指向插件内的完整上游工具包。读取当前类型的完整 schema、示例与作者规则，不把所有分支一次载入上下文。

| 类型 | 表达的问题 | Schema | 示例 |
| --- | --- | --- | --- |
| `architecture` | 组件、服务、边界与基础设施 | [schema](../../../vendor/archify/schemas/architecture.schema.json) | [Web 应用](../../../vendor/archify/examples/web-app.architecture.json) |
| `workflow` | 步骤、分支、审批与操作过程 | [schema](../../../vendor/archify/schemas/workflow.schema.json) | [工具调用](../../../vendor/archify/examples/agent-tool-call.workflow.json) |
| `sequence` | 参与者之间的调用、返回与时序 | [schema](../../../vendor/archify/schemas/sequence.schema.json) | [缓存请求](../../../vendor/archify/examples/cache-miss-request.sequence.json) |
| `dataflow` | 数据、资金或文件如何流转 | [schema](../../../vendor/archify/schemas/dataflow.schema.json) | [分析流程](../../../vendor/archify/examples/product-analytics.dataflow.json) |
| `lifecycle` | 状态、转移、重试与结束 | [schema](../../../vendor/archify/schemas/lifecycle.schema.json) | [发布生命周期](../../../vendor/archify/examples/deployment-release.lifecycle.json) |
| `erd` | 数据表、完整字段、键与关联 | [schema](../../../vendor/archify/schemas/erd.schema.json) | [订单结构](../../../vendor/archify/examples/orders.erd.json) |
| `class` | 类型、接口、成员及其关系 | [schema](../../../vendor/archify/schemas/class.schema.json) | [支付类型](../../../vendor/archify/examples/payments.class.json) |
| `tree` | 单父节点的包含与拆分 | [schema](../../../vendor/archify/schemas/tree.schema.json) | [模块树](../../../vendor/archify/examples/payment-platform.tree.json) |
| `timeline` | 有来源的时间点、事件与历史 | [schema](../../../vendor/archify/schemas/timeline.schema.json) | [故障时间线](../../../vendor/archify/examples/payment-incident.timeline.json) |
| `waterfall` | 同一时间轴上的耗时、重叠与嵌套 | [schema](../../../vendor/archify/schemas/waterfall.schema.json) | [请求耗时](../../../vendor/archify/examples/checkout-request.waterfall.json) |

非 architecture 原生模式同时读取 [公共 schema](../../../vendor/archify/schemas/common.schema.json)。类型仍不明确时可用已安装 CLI 的 `guide` 取得建议，不凭名称猜测约束字段。

ERD 保留实际字段、SQL 类型、键与外键引用，按上游 schema 表达多个键角色和功能域。分组与布局不能代替数据结构，也不能因表格密集就把字段移入无关卡片。

修正图形时保留业务含义，按工具具体诊断调整相连区域；节点、边、来源和标签不能为了通过布局验证随意删除。
