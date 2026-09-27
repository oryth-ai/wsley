# Wsley

Wsley 是面向 Ubuntu 的开发环境管理器，覆盖系统工具、终端配置、语言运行时、开发应用及 Codex skills，提供从环境初始化到日常维护的统一命令行入口。

项目基于 Shell 脚本实现，以模块为单位组织软件、配置与运行依赖，支持独立安装、分组批量操作、软件升级及本地状态查询。各模块负责配套环境的安装与配置，组件范围、操作说明和环境要求通过命令行统一展示。

## 快速开始

```bash
git clone https://github.com/oryth-ai/wsley.git ~/.local/share/wsley
mkdir -p ~/.local/bin
ln -s ~/.local/share/wsley/wsley/main.sh ~/.local/bin/wsley
export PATH="$HOME/.local/bin:$PATH"
```

## 命令说明

| 命令                             | 说明                                     |
| -------------------------------- | ---------------------------------------- |
| `wsley list`                     | 查看全部分组与模块                       |
| `wsley list <模块名或分组名>`    | 查看组件、操作说明与环境要求，或分组清单 |
| `wsley install <模块名或分组名>` | 安装所选模块，或批量安装分组内的模块     |
| `wsley upgrade <模块名或分组名>` | 升级所选模块或分组                       |
| `wsley status <模块名或分组名>`  | 查询本地安装与配置状态                   |
| `wsley update`                   | 更新 Wsley 自身                          |
| `wsley help`                     | 查看命令帮助                             |
