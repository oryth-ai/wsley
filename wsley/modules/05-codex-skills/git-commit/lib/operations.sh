#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

# shellcheck source=wsley/lib/skills.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/skills.sh"

skill_name="$(component_ids "$module_components" bundled)"
skill_assets="$module_directory/assets/$skill_name"

preflight_module() {
    require_ubuntu
    require_user
    require_command apt dpkg-query sudo
    require_command cp mv mktemp
    [[ -r "$skill_assets/SKILL.md" ]] || fail 'Missing bundled skill: git-commit'
}

install_skill() {
    if ! command -v git > /dev/null; then
        local -a missing_packages=()
        mapfile -t missing_packages < <(component_ids "$module_components" apt-missing)
        apt_install "${missing_packages[@]}"
    fi
    install_bundled_skill "$skill_assets"
}

show_skill_status() {
    skill_status "$skill_name"
    command_status git "$(command -v git || true)" --version
}
