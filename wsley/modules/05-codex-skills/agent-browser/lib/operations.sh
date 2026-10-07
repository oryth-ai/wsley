#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

# shellcheck source=wsley/lib/skills.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/skills.sh"

mapfile -t skill_names < <(component_ids "$module_components" skill)

skill_repository=vercel-labs/agent-browser

preflight_module() {
    preflight_remote_skills
}

install_skill() {
    install_remote_skill "$skill_repository" "${skill_names[@]}"
    install_browser_cli
}

upgrade_skill() {
    upgrade_remote_skill "$skill_repository" "${skill_names[@]}"
    upgrade_browser_cli
}

install_browser_cli() {
    load_skill_runtime
    if command -v agent-browser > /dev/null; then
        print_message info 'Skipped Agent Browser CLI: already installed.\n'
        return 0
    fi
    provision_browser_cli
}

upgrade_browser_cli() {
    load_skill_runtime
    if ! command -v agent-browser > /dev/null; then
        print_message info 'Skipped Agent Browser CLI: not installed; use wsley install.\n'
        return 0
    fi
    provision_browser_cli
}

provision_browser_cli() {
    local -a cli_packages=()

    prepare_node
    mapfile -t cli_packages < <(component_ids "$module_components" pnpm)
    pnpm add --global --allow-build=agent-browser --yes "${cli_packages[@]}"
    require_command agent-browser
    configure_apt_mirror
    agent-browser install --with-deps
    agent-browser --version
}

show_skill_status() {
    skill_status "${skill_names[@]}"
    load_skill_runtime
    command_status agent-browser "$PNPM_HOME/bin/agent-browser" --version
    if command -v agent-browser > /dev/null; then
        print_message muted 'Chromium: not checked by this status command.\n'
    fi
}
