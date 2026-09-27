#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

# shellcheck source=wsley/lib/skills.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/skills.sh"

skill_name="$(component_ids "$module_components" bundled)"
skill_assets="$module_directory/assets/$skill_name"

preflight_module() {
    require_user
    require_command cp mv mktemp
    [[ -r "$skill_assets/SKILL.md" ]] || fail 'Missing bundled skill: codebase-design'
}

install_skill() {
    install_bundled_skill "$skill_assets"
}

show_skill_status() {
    skill_status "$skill_name"
}
