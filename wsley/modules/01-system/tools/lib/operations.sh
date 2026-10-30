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
    local keyring=/etc/apt/keyrings/githubcli-archive-keyring.gpg
    local source_list=/etc/apt/sources.list.d/github-cli.list
    local state

    state="$(package_state gh)"
    if [[ "$state" == installed ]]; then
        return
    fi
    if [[ (-e "$keyring" || -L "$keyring") && (-e "$source_list" || -L "$source_list") ]]; then
        return
    fi

    make_workdir
    if [[ ! -e "$keyring" && ! -L "$keyring" ]]; then
        require_command curl
        download https://cli.github.com/packages/githubcli-archive-keyring.gpg "$work/github.gpg"
        system_replace_file "$work/github.gpg" "$keyring" 0644
    fi
    if [[ ! -e "$source_list" && ! -L "$source_list" ]]; then
        printf 'deb [arch=%s signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' "$(dpkg --print-architecture)" > "$work/github.list"
        system_replace_file "$work/github.list" "$source_list" 0644
    fi
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

    install_uv
    load_uv_tools

    for tool in "${uv_tools[@]}"; do
        if ! uv_tool_version "$tool" > /dev/null; then
            uv tool install "$tool"
        fi
    done
}

upgrade_uv_tools() {
    local tool

    upgrade_uv
    load_uv_tools
    for tool in "${uv_tools[@]}"; do
        if uv_tool_version "$tool" > /dev/null; then
            uv tool upgrade "$tool"
        else
            print_message info 'Skipped %s: not installed.\n' "$tool"
        fi
    done
}
