---
name: ppt-master
description: Create, edit, reconstruct and export presentations using the installed PPT Master workflow and resources. Use for editable PPTX, templates, slide reconstruction, narration and presentation-authored video. Preserve upstream routing, attribution checks and user confirmation gates.
---

# Presentations

将内容、设计与可编辑演示产物连接起来，使用随插件安装的完整 PPT Master 工具包。Sidekick 维护任务范围、环境和交付归属，上游工具维护格式、脚本、模板与具体演示流程。

## 进入工具流程

从本文件的实际位置解析 [PPT Master 指令](../../vendor/ppt-master/SKILL.md)，完整读取该文件。它所在的绝对目录就是 `SKILL_DIR`，不是本适配技能的目录，也不依赖当前工作目录或额外仓库搜索。

使用 [运行环境](../mira/references/runtime.md) 中的演示解释器执行上游要求的归属校验，再按其路由读取当前操作的流程和资料。校验失败时停止对应流程，不修补、绕过或伪造校验结果；上游完整包及其原始声明保持不变。

## 执行与衔接

根据用户需求选择生成、重建、美化、模板创建或原生编辑等具体路径，保留上游实际适用的确认门槛、文件契约和阶段顺序。已经形成的任务目标和用户授权继续有效，工具示例不能替换产品事实或扩大交付范围。

上游命令中的 `python` 与 `python3` 使用已安装的演示解释器，`skills/ppt-master/` 前缀按 `SKILL_DIR` 展开。环境安装和升级由 Wsley 完成，任务流程只处理所需的输入、内容、素材、模板与输出。

API、图像、音频和其他远程服务按用户实际配置与授权使用；已有依赖不等于拥有服务权限。设计材料、预览和正式产物放在任务约定位置，不写入插件、工具包或环境目录。

## 验证与交付

执行所选上游流程要求的内容、格式、可编辑性与视觉验证。修改原有演示时保留未授权改变的页、对象和结构，导出后核对实际文件及请求的页面范围。

交付正式产物和必要预览，说明实际完成、验证和缺口。PPTX 文件存在不证明视觉质量、原生对象可编辑或音视频已经通过，分别保留对应证据。
