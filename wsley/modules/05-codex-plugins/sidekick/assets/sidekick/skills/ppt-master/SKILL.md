---
name: ppt-master
description: Create, edit, reconstruct and export presentations using the installed PPT Master workflow and resources. Use for editable PPTX, templates, slide reconstruction, narration and presentation-authored video. Apply version-matched routing and file checks within the user's scope and confirmed choices.
---

# Presentations

将内容、设计与可编辑演示产物连接起来，使用随插件安装的完整 PPT Master 工具包。Sidekick 维护任务范围、环境和交付归属，上游工具维护格式、脚本、模板与具体演示流程。

## 进入工具流程

从本文件的实际位置解析 [PPT Master 指令](../../vendor/ppt-master/SKILL.md)，完整读取该文件。它所在的绝对目录就是 `SKILL_DIR`，不是本适配技能的目录，也不依赖当前工作目录或额外仓库搜索。

使用 [运行环境](../mira/references/runtime.md) 中的演示解释器执行上游要求的归属校验，再按其路由读取当前操作的流程和资料。校验失败时停止对应流程，不修补、绕过或伪造校验结果；上游完整包及其原始声明保持不变。

## 执行与衔接

根据用户需求选择生成、重建、美化、模板创建或原生编辑等具体路径，遵循实际文件契约和依赖顺序。进入确认环节时先核对已明确的内容、设计、页面范围和授权，只将尚未解决且影响后续工作的决定交给用户；用户已确认或明确委派的事项直接承接，不因上游模板再次要求相同批准。

上游的目录名、页面示例、角色播报和固定交付话术用于理解工具流程，按当前项目与用户语言组织实际工作。格式要求、归属校验与产物验证保留，推广、模型推荐、外部服务和插件自身修改不随制作任务自动执行。

上游命令中的 `python` 与 `python3` 使用已安装的演示解释器，`skills/ppt-master/` 前缀按 `SKILL_DIR` 展开。环境安装和升级由 Wsley 完成，任务流程只处理所需的输入、内容、素材、模板与输出。

API、图像、音频和其他远程服务按用户实际配置与授权使用；已有依赖不等于拥有服务权限。设计材料、预览和正式产物放在任务约定位置，不写入插件、工具包或环境目录。

## 验证与交付

执行所选上游流程要求的内容、格式、可编辑性与视觉验证。修改原有演示时保留未授权改变的页、对象和结构，导出后核对实际文件及请求的页面范围。

交付正式产物和必要预览，说明实际完成、验证和缺口。PPTX 文件存在不证明视觉质量、原生对象可编辑或音视频已经通过，分别保留对应证据。
