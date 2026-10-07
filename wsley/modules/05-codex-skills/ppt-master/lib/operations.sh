#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

# shellcheck source=wsley/lib/skills.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/skills.sh"

# shellcheck source=wsley/lib/python.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/python.sh"

mapfile -t skill_names < <(component_ids "$module_components" skill)

skill_repository=hugohe3/ppt-master

preflight_module() {
    preflight_remote_skills
}

configure_skill_runtime() (
    local directory="$1" temporary

    temporary="$(mktemp)"
    trap 'rm -f -- "$temporary"' EXIT
    awk '
        /^## Wsley runtime$/ { skip = 1; blanks = ""; next }
        /^## / { skip = 0 }
        skip { next }
        /^[[:space:]]*$/ { blanks = blanks $0 ORS; next }
        { printf "%s%s\n", blanks, $0; blanks = "" }
    ' "$directory/SKILL.md" > "$temporary"
    cat "$module_directory/assets/runtime.md" >> "$temporary"
    cat "$temporary" > "$directory/SKILL.md"
)

install_skill() {
    local environment

    install_remote_skill "$skill_repository" "${skill_names[@]}"
    apt_install "${module_packages[@]}"
    install_uv
    environment="$installed_skill_directory/.venv"

    if [[ -x "$environment/bin/python" ]] &&
        "$environment/bin/python" -B -c 'import pptx, yaml, PIL, fitz, requests, flask, openpyxl' > /dev/null 2>&1 &&
        uv pip check --python "$environment/bin/python"; then
        print_message info 'PPT Master Python environment ready.\n'
        return 0
    fi
    provision_skill_environment "$installed_skill_directory"
}

upgrade_skill() {
    upgrade_remote_skill "$skill_repository" "${skill_names[@]}"
    [[ "$skill_changed" == true ]] || return 0

    apt_upgrade "${module_packages[@]}"
    install_uv
    provision_skill_environment "$installed_skill_directory"
}

provision_skill_environment() {
    local directory="$1" requirements environment

    environment="$directory/.venv"
    requirements="$directory/$(component_ids "$module_components" requirements)"
    [[ -f "$requirements" ]] || fail 'PPT Master requirements.txt is missing.'
    if [[ ! -x "$environment/bin/python" ]]; then
        uv venv --python "$(component_ids "$module_components" python-runtime)" "$environment"
    fi
    uv pip install --python "$environment/bin/python" -r "$requirements"
    uv pip check --python "$environment/bin/python"

    if [[ "$skill_changed" == true ]]; then
        configure_skill_runtime "$directory"
    fi
}

show_skill_status() {
    local directory environment

    directory="$(skill_path "${skill_names[0]}")" || directory="$skill_directory/${skill_names[0]}"
    environment="$directory/.venv"

    skill_status "${skill_names[@]}"
    package_status "${module_packages[@]}"
    if [[ -x "$environment/bin/python" ]]; then
        "$environment/bin/python" -B -c 'import pptx, yaml, PIL, fitz, requests, flask, openpyxl; print("PPT Master Python core imports: available")'
    else
        print_message warning '%s\n' 'PPT Master Python: not-installed'
    fi
}
