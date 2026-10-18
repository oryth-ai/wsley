#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

# shellcheck source=wsley/lib/skills.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/skills.sh"

skill_name="$(component_ids "$module_components" bundled Skill)"
skill_assets="$module_directory/assets/$skill_name"
mapfile -t required_skills < <(component_ids "$module_components" bundled 'Required skills')

preflight_module() {
    local name

    require_ubuntu
    require_user
    require_command apt dpkg-query sudo
    require_command cp mv mktemp
    for name in "$skill_name" "${required_skills[@]}"; do
        [[ -r "$module_directory/../$name/assets/$name/SKILL.md" ]] || fail "Missing bundled skill: $name"
    done
}

install_skill() {
    local name

    if ! command -v git > /dev/null; then
        local -a missing_packages=()
        mapfile -t missing_packages < <(component_ids "$module_components" apt-missing)
        apt_install "${missing_packages[@]}"
    fi
    for name in "${required_skills[@]}"; do
        install_bundled_skill "$module_directory/../$name/assets/$name"
    done
    install_bundled_skill "$skill_assets"
}

upgrade_skill() {
    upgrade_bundled_skill "$skill_assets"
}

show_skill_status() {
    skill_status "$skill_name" "${required_skills[@]}"
    command_status git "$(command -v git || true)" --version
}
