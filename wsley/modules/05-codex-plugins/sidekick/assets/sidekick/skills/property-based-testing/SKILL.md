---
name: property-based-testing
description: Design, review and debug property-based tests for invariants, round trips, normalization, parsers and state machines. Use when generated input domains can test a real contract. Distinguish product bugs, incorrect properties, invalid generators and undefined behavior.
---

# Property-Based Testing

把已确认的规则表达为覆盖输入域的性质，让生成器寻找可解释的反例。代码缺少适用性质时使用普通示例测试；属性测试不以随机次数或“不崩溃”代替有效断言。

## 选择性质

读取需求、协议、类型、实现和现有测试，先确定有效输入域与真实保证。函数名称和现有实现只能提供线索，不能推翻用户已确认的契约。按 [性质与生成](references/properties.md) 选择断言。

| 性质 | 适用的约束 |
| --- | --- |
| 往返或逆变换 | 编码与解码、保存与读取，在契约允许的等价关系下恢复 |
| 幂等 | 格式化、标准化、去重等重复应用后结果不再变化 |
| 不变量 | 守恒、上限、权限屏障、有效状态与资源所有权 |
| 独立参考结果 | 优化或替换实现与简单可信 oracle 一致 |
| 组合关系 | 在业务确实保证时验证交换、结合、单位元或顺序关系 |
| 可独立验证的结果 | 排序、约束满足等复杂输出能被较简单的规则检查 |

断言应能被错误实现推翻。重新计算同一算法、比较结果与自身或过滤掉几乎所有输入都可能使测试无效；有状态函数的两次调用则可能构成真正的确定性验证。

## 编写与重构

复用项目已采用的 Hypothesis、fast-check、proptest、rapid 等工具。没有对应依赖时先说明具体性质与收益，依赖选择按任务和项目授权处理，不因匹配本技能默认安装库。

性质被 I/O、拼接字符串或原地变更遮住时，先判断是否值得提取纯规则、结构化表示、返回值或可控依赖。重构服务于真实接口与测试收益，不为测试复制实现或公开私有状态。

## 审查与故障解释

审查生成器是否真正覆盖目标域、断言是否独立，以及有效执行的输入数量与资源预算。失败后按 [反例与状态机](references/failures.md) 核对契约、缩减结果和执行状态，分别修复产品、性质、生成器或夹具。

原始支持范围未定义的输入保持未定义或待确认，不通过扩大兼容性、补造业务事实、削弱断言或屏蔽失败使测试通过。需要测试边界及并发语义时衔接相关语言和依赖的验证方式。

## 交付

修改遵循 [disciplined-dev](../disciplined-dev/SKILL.md)。交付被验证的保证、输入域、实际执行预算、可复现反例及未覆盖边界；有限生成不能被表述为已证明整个输入域正确。
