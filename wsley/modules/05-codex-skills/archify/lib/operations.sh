#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

# shellcheck source=wsley/lib/skills.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/skills.sh"

mapfile -t skill_names < <(component_ids "$module_components" skill)

skill_repository=tt-a1i/archify

preflight_module() {
    preflight_remote_skills
}

install_skill() {
    install_remote_skill "$skill_repository" "${skill_names[0]}" validate_archify
}

upgrade_skill() {
    upgrade_remote_skill "$skill_repository" "${skill_names[0]}" validate_archify
}

validate_archify() {
    node "$1/bin/archify.mjs" doctor
}

show_skill_status() {
    local directory

    skill_status "${skill_names[@]}"
    load_skill_runtime
    command_status node "$PNPM_HOME/bin/node" --version
    if command -v node > /dev/null && directory="$(skill_path archify)"; then
        ARCHIFY_UPDATE_CHECK_DISABLED=1 node "$directory/bin/archify.mjs" doctor
    fi
}
