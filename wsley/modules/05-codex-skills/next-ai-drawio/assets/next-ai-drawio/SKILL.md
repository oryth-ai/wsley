---
name: next-ai-drawio
description: Create, edit, and export editable draw.io diagrams with a live browser canvas through the drawio MCP server. Use for draw.io, diagrams.net, Next AI Draw.io, .drawio or .drawio.svg files, or diagrams the user wants to edit by hand in draw.io, including architecture diagrams, flowcharts, sequence diagrams and ER diagrams. Not for standalone HTML/SVG visualizations without a draw.io requirement.
---

# Next AI Draw.io

通过 `drawio` MCP 工具创建和编辑图表，交付可继续手动修改的 draw.io 文件。图表内容由当前 agent 生成，MCP 提供画布、预览、版本和导出，无须单独调用模型 API。

## 会话与输入

- 确认 `drawio` MCP 工具可用。缺失时说明需要安装模块并重启 Codex；不要自行改写用户的 MCP 配置或启动完整 Web 应用代替。
- 调用 `start_session`，读取返回的绘图指南并按其布局、连线和样式约束绘制。指南不在上下文时调用 `get_drawing_guide`；使用云服务等图标前通过 `get_shape_library` 获取真实形状标识。
- 将返回的预览 URL 提供给用户。浏览器与服务位于不同机器时，按实际端口说明转发方式，保留 URL 中连接会话所需的参数。
- 依据用户需求或实际读取的代码、文档确定节点、关系与边界。用户指定 draw.io 时保留该交付格式；只有关键内容无法确定时才澄清。
- 修改现有 `.drawio` 或 `.drawio.svg` 时，先用 `load_diagram` 载入绝对路径。继续此前会话时，通过 `list_saved_diagrams` 定位并用 `start_session` 的 `session_id` 恢复，避免重新创建空白图表。

## 绘制与修改

- 新图使用 `create_new_diagram` 提交工具要求的 XML。它会替换整个文档；修改已有内容使用 `edit_diagram`，增加页面使用 `add_page`。
- 载入文件、恢复会话或不确定当前画布内容时，用 `get_diagram` 读取状态；已知的当前状态可以复用。用户提到选中元素时用 `get_selection` 获取具体对象。按实际页面和 cell id 修改，保留用户手工调整；工具提示画布已变化时，按返回的新状态重新组织操作。
- 通过 MCP 修改并导出文件，不直接重写磁盘上的 XML 或自动保存文件。按工具返回的错误修正操作；不要在编辑失败后用整图替换绕过冲突。
- 完成绘制后用 `screenshot_diagram` 或写操作的 `screenshot` 参数查看渲染结果，检查遮挡、文字、连线和方向。截图及 PNG/SVG 导出依赖已连接的预览页；超时时先让页面打开并置前，再重试受影响的操作。

## 保存与交付

用 `export_diagram` 将结果保存到明确的绝对路径。交付 `.drawio`，或用户要求的 `.drawio.svg`、PNG、SVG；只有浏览器自动保存不代表目标文件已经更新。修改已有文件时导出回对应路径。

交付时给出文件位置和预览 URL。截图或图片导出受环境限制时，说明实际已保存的文件和未完成部分，不将 XML 创建成功表述为已完成视觉检查。

会话默认自动保存到 `~/.next-ai-drawio/`，但只保留最近的有限数量，不能代替正式交付。用户需要长期绘图偏好时，可使用该目录的 `instructions.md`；不要把单次任务要求写入全局偏好。
