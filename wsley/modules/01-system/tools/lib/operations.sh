#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

# shellcheck source=wsley/lib/python.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/python.sh"

mapfile -t uv_tools < <(component_ids "$module_components" uv-tool)

require_apt() {
    local command

    for command in apt apt-cache dpkg-query dpkg; do
        command -v "$command" > /dev/null || {
            print_message error 'Missing command: %s. The tools module requires APT.\n' "$command" >&2
            exit 1
        }
    done
}

configure_github_source() {
    require_command curl
    make_workdir
    download https://cli.github.com/packages/githubcli-archive-keyring.gpg "$work/github.gpg"

    system_backup /etc/apt/keyrings/githubcli-archive-keyring.gpg
    as_root install -D -m 0644 "$work/github.gpg" /etc/apt/keyrings/githubcli-archive-keyring.gpg
    printf 'deb [arch=%s signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' "$(dpkg --print-architecture)" > "$work/github.list"
    system_backup /etc/apt/sources.list.d/github-cli.list
    as_root install -m 0644 "$work/github.list" /etc/apt/sources.list.d/github-cli.list
}

load_uv_tools() {
    uv_inventory=''
    if command -v uv > /dev/null; then
        uv_inventory="$(uv tool list)"
    fi
}

uv_tool_version() {
    awk -v name="$1" '$1 == name && $2 ~ /^v/ {sub(/^v/, "", $2); print $2; found=1; exit} END {if (!found) exit 1}' <<< "$uv_inventory"
}

install_uv_tools() {
    local tool

    prepare_uv install
    load_uv_tools

    for tool in "${uv_tools[@]}"; do
        if ! uv_tool_version "$tool" > /dev/null; then
            uv tool install "$tool"
        fi
    done
}

upgrade_uv_tools() {
    local tool

    prepare_uv upgrade
    load_uv_tools
    for tool in "${uv_tools[@]}"; do
        if uv_tool_version "$tool" > /dev/null; then
            uv tool upgrade "$tool"
        else
            uv tool install "$tool"
        fi
    done
}
