# 运行环境

Wsley 的安装和升级命令准备并验证浏览器、演示文稿和 MCP 运行环境。技能执行以环境已完备为前提，直接使用下列路径，不在任务开始、切换技能或恢复上下文时重复检查和安装依赖。实际命令出现环境错误时，说明具体失败，由 `wsley install sidekick` 补齐依赖，或按用户要求执行 `wsley upgrade sidekick` 同步技能与依赖。

插件内保存指令、脚本、模板、许可证及静态资源。运行目录为 `${XDG_DATA_HOME:-$HOME/.local/share}/sidekick/runtimes`，以下以 `<runtime>` 表示其实际绝对路径。浏览器下载与 Python 基础解释器缓存遵循 agent-browser 和 uv 的配置，同样位于插件目录之外。任务产物遵循所属项目规则。

## 浏览器

使用 `<runtime>/agent-browser/node_modules/.bin/agent-browser`，以此替换上游说明中的 `agent-browser`。模块已安装对应版本的 CLI、Chromium 和 Linux 系统依赖。

先通过该路径执行 `skills get core` 并完整读取实际版本的使用说明；Electron、QA 等专项说明按任务需要读取。读取命令说明不触发环境准备，不执行上游的独立安装或自更新示例。

页面操作和交互验证仍以真实浏览器结果为证据。

## 演示文稿

本地 [ppt-master](../../ppt-master/SKILL.md) 说明适配约定，完整上游资源位于插件的 `vendor/ppt-master`。将该工具资源目录的实际绝对路径作为 `SKILL_DIR`，使用 `<runtime>/ppt-master/.venv/bin/python` 执行其脚本，按上游要求保留归属校验、路由和产物验证。

模块已准备 Python 3.12、完整的 `requirements.txt` 依赖、LibreOffice、Pandoc、FFmpeg、Fontconfig 及基础中英文字体。上游示例中的 `python3` 和 `python` 使用上述解释器，不另建虚拟环境或在项目中安装技能依赖。

API 密钥、模型服务、账户权限和远程提供商属于任务配置，按用户实际选择与授权使用。环境安装不代表已获得外部服务权限。

## 图解与纯文档能力

[archify](../../archify/SKILL.md) 使用插件 `vendor/archify/bin/archify.mjs` 的实际绝对路径和已安装的 Node.js。调用时设置 `ARCHIFY_CHROME=<runtime>/chromium` 与 `ARCHIFY_UPDATE_CHECK_DISABLED=1`，直接使用模块已绑定的 Chromium，不自行搜索或安装另一套浏览器。

可编辑 draw.io 使用插件 `mcp.json` 中指向已安装程序的服务，以实际工具连接和导出结果验证。

`user-research`、`ux-copy` 等文档能力直接读取对应 `SKILL.md` 和按需引用资料，不创建专用环境。上游的示例时长、人数和交付模板用于判断，不能冒充真实研究证据或自动扩大交付范围。
