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
    install_remote_skills "$skill_repository" "${skill_names[@]}"

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
    printf '%s\n' 'Browser readiness requires a live browser session; version alone does not verify Chromium.'
}
