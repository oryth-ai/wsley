#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

# shellcheck source=wsley/lib/skills.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/skills.sh"

mapfile -t skill_names < <(component_ids "$module_components" skill)

skill_repository=oil-oil/beautify-github-readme

preflight_module() {
    preflight_remote_skills
}

install_skill() {
    install_remote_skill "$skill_repository" "${skill_names[@]}"
}

upgrade_skill() {
    upgrade_remote_skill "$skill_repository" "${skill_names[@]}"
}

show_skill_status() {
    skill_status "${skill_names[@]}"
}
