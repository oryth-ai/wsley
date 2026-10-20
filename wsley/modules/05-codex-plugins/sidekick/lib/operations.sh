#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

# shellcheck source=wsley/lib/node.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/node.sh"

# shellcheck source=wsley/lib/python.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/python.sh"

plugin_script="$module_directory/lib/plugin.py"
plugin_configuration="${CODEX_HOME:-$HOME/.codex}/config.toml"

preflight_module() {
    require_ubuntu
    require_user
    require_command apt dpkg-query sudo awk cp mv mktemp codex
    validate_node_environment
    [[ "$plugin_configuration" == /* ]] || fail 'CODEX_HOME must be an absolute path.'
    [[ "${XDG_DATA_HOME:-$HOME/.local/share}" == /* ]] || fail 'XDG_DATA_HOME must be an absolute path.'
    [[ -r "$module_directory/assets/sidekick/plugin.json" ]] || fail 'Missing Sidekick plugin manifest.'
    [[ -r "$module_directory/assets/upstream.json" ]] || fail 'Missing Sidekick upstream catalog.'
    codex plugin add --help > /dev/null
    codex plugin marketplace add --help > /dev/null
    codex plugin list --json > /dev/null
}

install_plugin() {
    apt_install "${module_packages[@]}"
    prepare_node
    install_uv
    /usr/bin/python3 -B "$plugin_script" install "$module_directory"
}

upgrade_plugin() {
    local result

    if /usr/bin/python3 -B "$plugin_script" installed "$module_directory"; then
        run_apt_install "${module_packages[@]}"
        prepare_node
        install_uv
        /usr/bin/python3 -B "$plugin_script" upgrade "$module_directory"
    else
        result=$?
        ((result == 1)) || return "$result"
        print_message info 'Skipped Sidekick: not installed; use wsley install.\n'
    fi
}

show_plugin_status() {
    /usr/bin/python3 -B "$plugin_script" status "$module_directory"
    command_status node "$PNPM_HOME/bin/node" --version
    command_status uv "$HOME/.local/bin/uv" --version
    package_status "${module_packages[@]}"
}
