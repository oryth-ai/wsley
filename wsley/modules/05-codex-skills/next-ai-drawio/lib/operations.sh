#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

# shellcheck source=wsley/lib/skills.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/skills.sh"

skill_name="$(component_ids "$module_components" bundled)"
skill_assets="$module_directory/assets/$skill_name"
codex_configuration="${CODEX_HOME:-$HOME/.codex}/config.toml"

preflight_module() {
    require_ubuntu
    require_user
    require_command apt dpkg-query sudo codex
    load_skill_runtime
    validate_node_environment
    [[ -r "$skill_assets/SKILL.md" ]] || fail 'Missing bundled skill: next-ai-drawio'
    [[ "$codex_configuration" == /* ]] || fail 'CODEX_HOME must be an absolute path.'
    codex mcp list > /dev/null
}

install_skill() {
    install_bundled_skill "$skill_assets"
    load_skill_runtime
    if command -v next-ai-drawio-mcp > /dev/null; then
        print_message info 'Skipped Next AI Draw.io MCP package: already installed.\n'
    else
        provision_drawio_server
    fi
    configure_drawio_server
}

upgrade_skill() {
    upgrade_bundled_skill "$skill_assets"
    load_skill_runtime
    if ! command -v next-ai-drawio-mcp > /dev/null; then
        print_message info 'Skipped Next AI Draw.io MCP package: not installed; use wsley install.\n'
        return 0
    fi
    provision_drawio_server
    configure_drawio_server
}

provision_drawio_server() {
    local -a packages=()

    prepare_node
    mapfile -t packages < <(component_ids "$module_components" pnpm)
    (cd / && pnpm add --global "${packages[@]}")
    require_command next-ai-drawio-mcp
}

configure_drawio_server() {
    if codex mcp get drawio > /dev/null 2>&1; then
        print_message info 'Skipped Codex drawio registration: existing configuration preserved.\n'
        return 0
    fi

    codex mcp list > /dev/null
    backup_file "$codex_configuration" || return
    codex mcp add drawio -- "$(command -v next-ai-drawio-mcp)"
}

show_skill_status() {
    local executable

    skill_status "$skill_name"
    load_skill_runtime
    command_status node "$PNPM_HOME/bin/node" --version
    if executable="$(command -v next-ai-drawio-mcp)"; then
        print_message success '%-30s installed  %s\n' 'Next AI Draw.io MCP package' "$executable"
    else
        print_message warning '%-30s not-installed\n' 'Next AI Draw.io MCP package'
    fi

    if ! command -v codex > /dev/null; then
        print_message warning '%-30s unavailable: Codex CLI not installed\n' 'Codex drawio registration'
        return 0
    fi
    codex mcp list > /dev/null
    if codex mcp get drawio > /dev/null 2>&1; then
        print_message success '%-30s present  %s\n' 'Codex drawio registration' "$codex_configuration"
    else
        print_message warning '%-30s missing  %s\n' 'Codex drawio registration' "$codex_configuration"
    fi
    print_message muted 'MCP connectivity and browser rendering are not checked by this status command.\n'
}
