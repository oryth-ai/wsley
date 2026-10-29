# 专项能力选择

按当前问题和项目实际技术栈选择能力，读取本插件内对应的 `SKILL.md` 后使用。这里维护问题与能力之间的联系，具体方法由各技能负责；技能缺失时按主入口的缺项处理规则继续。

## 产品与设计

| 实际问题 | 采用的技能 | 结果如何进入后续工作 |
| --- | --- | --- |
| 业务术语、事实所有权、生命周期与不变量不清 | [domain-modeling](../../domain-modeling/SKILL.md) | 用明确的概念和规则约束数据、接口、实现及验收 |
| 模块边界、依赖和测试接缝妨碍维护 | [codebase-design](../../codebase-design/SKILL.md) | 确定负责行为的模块、接口与必要重构范围 |
| 缺少用户需求、使用行为或可用性证据 | [user-research](../../user-research/SKILL.md) | 将研究证据与设计假设分开，明确需要验证的用户任务 |
| 需要探索界面方向、视觉方案和交互层级 | [oil-ui](../../oil-ui/SKILL.md) | 用确定的设计决定指导页面和组件实现 |
| 界面文案、术语和状态反馈影响理解 | [ux-copy](../../ux-copy/SKILL.md) | 将措辞用于相应状态、错误和本地化资源 |

## 前端与体验

| 实际问题 | 采用的技能 | 结果如何进入后续工作 |
| --- | --- | --- |
| 新建或重做 Web 页面、应用界面与组件，需要具体视觉设计与实现 | [frontend-design](../../frontend-design/SKILL.md) | 将主题、排版、色彩、布局与交互落实为可运行且经过实际查看的界面 |
| 界面实现需要对照 Web 规范检查 | [web-design-guidelines](../../web-design-guidelines/SKILL.md) | 记录具体实现偏差，保持项目现有设计与技术选择 |
| 键盘、焦点、语义和辅助技术访问存在障碍 | [accessibility](../../accessibility/SKILL.md) | 连接交互状态、组件实现与实际可访问性验证 |
| React 渲染、数据获取、资源加载或交互有性能问题 | [vercel-react-best-practices](../../vercel-react-best-practices/SKILL.md) | 结合 React 与浏览器证据定位，在项目版本与运行方式内调整并比较 |
| 多语言资源、格式、排版或语言切换不一致 | [i18n-expert](../../i18n-expert/SKILL.md) | 同步界面、资源和语言行为，遵循项目目标语言范围 |
| 公开页面的抓取、索引或搜索呈现需要审计 | [seo-audit](../../seo-audit/SKILL.md) | 将发现落到公开路由、元数据和实际可验证的页面 |

## 后端与技术栈

| 实际问题 | 采用的技能 | 结果如何进入后续工作 |
| --- | --- | --- |
| FastAPI 接口、依赖、事务、请求性能或流式响应 | [fastapi-expert](../../fastapi-expert/SKILL.md) | 明确请求与资源边界，关联链路证据并验证接口、提交与收尾行为 |
| Python 计算、内存、数据处理或 I/O 性能问题 | [python-performance-optimization](../../python-performance-optimization/SKILL.md) | 区分进程内热点与外部等待，形成基线、归因、优化及前后证据 |
| Go goroutine 所有权、取消、竞争或泄漏 | [golang-concurrency](../../golang-concurrency/SKILL.md) | 明确启动、停止和回收责任，验收并发与退出行为 |
| Go 行为测试、夹具、模糊测试或竞争验证 | [golang-testing](../../golang-testing/SKILL.md) | 为实际行为缺口选择项目已有测试方式和有效断言 |
| Go 性能基线、benchmark、pprof、trace 或前后比较 | [golang-benchmark](../../golang-benchmark/SKILL.md) | 形成可复现测量，区分 CPU、分配、等待、调度与环境噪声 |
| Go 热点优化或性能代码审查 | [golang-performance](../../golang-performance/SKILL.md) | 用测量依据选择算法、内存、CPU、运行时及 I/O 改法，并验证收益与行为 |
| PostgreSQL 结构、锁、连接和查询性能 | [supabase-postgres-best-practices](../../supabase-postgres-best-practices/SKILL.md) | 根据项目契约与实际查询证据调整，不推导额外平台依赖 |

## 质量与运维

| 实际问题 | 采用的技能 | 结果如何进入后续工作 |
| --- | --- | --- |
| 状态机、数量关系或组合输入适合不变量验证 | [property-based-testing](../../property-based-testing/SKILL.md) | 从已确定的领域规则生成断言和输入，保留可解释的失败样例 |
| 变更影响信任边界、权限、敏感数据或外部依赖 | [security-and-hardening](../../security-and-hardening/SKILL.md) | 结合实际攻击路径确定拒绝行为、修复位置与安全验证 |
| 生产问题缺少日志、指标、追踪或有效告警 | [observability-and-instrumentation](../../observability-and-instrumentation/SKILL.md) | 在现有设施中补充诊断信号，并验证实际输出与信息保护 |
| 服务目标、容量、故障恢复或运行责任不明确 | [sre-engineer](../../sre-engineer/SKILL.md) | 将可靠性目标连接到容量、失败和恢复证据 |

## 研究与表达工具

| 实际问题 | 采用的技能 | 结果如何进入后续工作 |
| --- | --- | --- |
| 需要带主要来源和证据的技术研究报告 | [research](../../research/SKILL.md) | 将已证实结论、推断和未决事项分别用于后续设计 |
| 需要操作真实页面、复现交互或取得浏览器证据 | [agent-browser](../../agent-browser/SKILL.md) | 以实际页面行为验证问题和修复结果 |
| 需要可探索的独立 HTML 图解或一页说明 | [archify](../../archify/SKILL.md) | 根据实际要求和代码证据表达结构、状态或流程 |
| 需要可在 draw.io 中继续编辑的图 | [next-ai-drawio](../../next-ai-drawio/SKILL.md) | 交付所要求的可编辑文件及必要导出 |
| 需要可编辑演示文稿 | [ppt-master](../../ppt-master/SKILL.md) | 将确认的内容与设计转为相应演示产物 |
| 需要 GitHub README 视觉设计 | [beautify-github-readme](../../beautify-github-readme/SKILL.md) | 按用户指定范围制作首页或资源，遵循文档修改授权 |
| 用户要求寻找或安装尚未具备的技能 | [find-skills](../../find-skills/SKILL.md) | 先确定适用来源与能力，再按当前请求决定是否安装 |

工具只在其产物或操作为当前任务所需时参与。纯绘图、演示或研究报告由 Mira 直接路由至相应内部技能，无须先启动开发工作流。
