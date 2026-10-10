# Wsley

**用一套命令，搭建与维护 Ubuntu 开发环境。**

Wsley 将系统工具、终端配置、语言运行时、开发应用和 Codex skills 按模块组织。可以单独安装一个模块，也可以按分组批量管理；安装补齐缺失组件，升级更新已有组件并刷新模块管理的配置，状态查询帮助了解本机环境。

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

默认仓库位置为 `~/.local/share/wsley`，命令入口为 `~/.local/bin/wsley`。

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

| 命令                            | 作用                            |
| ------------------------------- | ------------------------------- |
| `wsley list [模块或分组]...`    | 列出模块与分组，或查看模块详情  |
| `wsley install <模块或分组>...` | 补装缺失组件                    |
| `wsley upgrade <模块或分组>...` | 更新已安装组件                  |
| `wsley status <模块或分组>...`  | 查询本地状态                    |
| `wsley self-upgrade`            | 更新 Wsley 仓库代码与 PATH 环境 |
| `wsley help`                    | 查看帮助                        |

模块名和分组名区分大小写，可混合传入。安装、升级和状态查询按参数顺序展开，每个模块只执行一次：

```bash
wsley install terminal node python
wsley status development codex
wsley upgrade node python --yes
```

各模块分别决定配置的创建、追加和替换规则，安装操作也可能替换已有配置。执行前可通过 `wsley list <模块>` 查看具体行为；安装或升级所需的运行时依赖会按需补齐。共享 PATH 配置保存在 `~/.config/wsley/environment/`，加载入口会注册到 Bash/Zsh 启动文件。

用户文件的首次备份位于 `${XDG_STATE_HOME:-$HOME/.local/state}/wsley/backups/`，系统文件的首次备份位于 `/var/lib/wsley/backups/`。同一路径的后续修改保留首次备份。

Skills 安装时保留已检测到的 skill，升级时整体替换 skill 目录，包括其中的本地修改。替换过程会备份已有副本，失败时恢复原目录；配套软件包的更新不随 skill 文件回退。安装目录为 `~/.agents/skills/<名称>`，已有的 `${CODEX_HOME:-$HOME/.codex}/skills/<名称>` 副本会在替换时整合为指向该目录的链接。

`install`、`upgrade` 和 `self-upgrade` 支持 `--yes`（或 `-y`），用于跳过操作确认；APT 镜像和 Docker 代理问题仍需交互选择。

## 环境要求

- **平台与权限**：面向 Ubuntu，多数模块需要 APT 和具有 `sudo` 权限的普通用户；具体要求可通过 `wsley list <模块>` 查看。
- **服务管理**：`docker` 和 `ssh` 需要正在运行的 systemd。
- **架构限制**：`chrome` 仅支持 amd64；`go` 支持 amd64 和 arm64。
- **字体来源**：`fonts` 在 `/mnt/c/Windows/Fonts` 可用时复制 Windows 字体，路径缺失时跳过复制。
- **环境生效**：涉及 PATH 或 Shell 配置的安装完成后，请打开新终端。

## 许可证

[MIT](LICENSE) · Copyright © 2026 Oryth AI
