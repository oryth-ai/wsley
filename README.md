# Wsley

**用一套命令，搭建与维护 Ubuntu 开发环境。**

Wsley 将系统工具、终端配置、语言运行时、开发应用和 Codex skills 按模块组织。可以单独安装一个模块，也可以按分组批量管理；安装补齐缺失组件，升级更新已有组件，状态查询帮助你了解本机环境。

[快速开始](#快速开始) · [模块概览](#模块概览) · [命令参考](#命令参考) · [环境要求](#环境要求)

## 快速开始

在普通用户终端中运行，无需为安装命令添加 `sudo`。需要安装系统依赖时，脚本会调用 `sudo`。

```bash
curl -fsSL https://raw.githubusercontent.com/oryth-ai/wsley/main/wsley/install.sh | bash
```

安装器部署 Wsley 命令、Bash / Zsh 补全和 Shell 环境配置，开发工具由你按需选择。安装完成后，**打开新终端**：

```bash
wsley list                  # 浏览全部模块与分组
wsley list node             # 查看组件、操作说明与环境要求
wsley install node          # 安装第一个模块
wsley status node           # 确认本地状态
```

默认仓库位置为 `~/.local/share/wsley`（遵循 `XDG_DATA_HOME`），命令入口为 `~/.local/bin/wsley`。

## 模块概览

分组名可直接用于命令，例如 `wsley install terminal`。

| 分组           | 模块                             | 管理范围                                    |
| -------------- | -------------------------------- | ------------------------------------------- |
| `system`       | `tools`、`fonts`、`ssh`          | 命令行工具、Windows 字体、OpenSSH 服务      |
| `terminal`     | `zsh`、`tmux`、`vim`             | Zsh / Oh My Zsh、终端复用与编辑器配置       |
| `development`  | `node`、`python`、`go`、`docker` | Node.js LTS / pnpm、Python / uv、Go、Docker |
| `applications` | `chrome`、`codex`、`libreoffice` | 浏览器、Codex CLI、办公套件                 |
| `codex-skills` | 见下方列表                       | Skill 文件及各模块配套的工具与依赖          |

<details>
<summary>查看 Codex skills 模块</summary>

- `agent-browser` — 浏览器自动化
- `archify` — 架构图
- `beautify-github-readme` — README 设计
- `codebase-design` — 模块与接口设计
- `coherent-change` — 项目变更一致性
- `git-commit` — 原子化 Git 提交
- `oil-ui` — 界面设计
- `ppt-master` — 演示文稿制作
- `research` — 基于证据的技术研究

</details>

具体组件、配置位置和操作行为以 `wsley list <模块>` 为准。

## 命令参考

| 命令                            | 作用                           |
| ------------------------------- | ------------------------------ |
| `wsley list [模块或分组]...`    | 列出模块与分组，或查看模块详情 |
| `wsley install <模块或分组>...` | 补装缺失组件                   |
| `wsley upgrade <模块或分组>...` | 更新已安装组件                 |
| `wsley status <模块或分组>...`  | 查询本地状态                   |
| `wsley self-upgrade`            | 更新 Wsley 仓库代码与 PATH 环境      |
| `wsley help`                    | 查看帮助                       |

模块名和分组名区分大小写，可混合传入。安装、升级和状态查询按参数顺序展开，每个模块只执行一次：

```bash
wsley install terminal node python
wsley status development codex
wsley upgrade node python --yes
```

升级 Zsh 会备份并覆盖 `.zshrc`、自带主题和自定义脚本；tmux / Vim 会补齐已有配置中的 Wsley 设置。Wsley 管理的环境脚本会在配置时同步更新，Node 的自定义 `PNPM_HOME` 会保留。首次备份位于 `${XDG_STATE_HOME:-$HOME/.local/state}/wsley/backups/`。

`install`、`upgrade` 和 `self-upgrade` 支持 `--yes`（或 `-y`），用于跳过操作确认；APT 镜像和 Docker 代理问题仍需交互选择。

## 环境要求

- **平台与权限**：面向 Ubuntu，多数模块需要 APT 和具有 `sudo` 权限的普通用户；具体要求可通过 `wsley list <模块>` 查看。
- **服务管理**：`docker` 和 `ssh` 需要正在运行的 systemd。
- **架构限制**：`chrome` 仅支持 amd64；`go` 支持 amd64 和 arm64。
- **字体来源**：`fonts` 从 `/mnt/c/Windows/Fonts` 复制 Windows 字体，使用前需确保该路径可用。
- **环境生效**：涉及 PATH 或 Shell 配置的安装完成后，请打开新终端。

## 参与开发

模块源码位于 [`wsley/modules/`](wsley/modules/)，每个模块通过 `module.info` 描述行为，并提供安装、升级和状态查询脚本。

在仓库根目录运行 `make check` 可执行静态检查；开发工具和 Git hooks 的安装方式见 [`Makefile`](Makefile)。

## 许可证

[MIT](LICENSE) · Copyright © 2026 Oryth AI
