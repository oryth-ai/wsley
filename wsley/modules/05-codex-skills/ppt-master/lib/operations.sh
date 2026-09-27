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
    # Replace the owned section while preserving upstream metadata and other sections.
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
    local requirements environment

    install_remote_skills "$skill_repository" "${skill_names[@]}"
    environment="$installed_skill_directory/.venv"
    requirements="$installed_skill_directory/$(component_ids "$module_components" requirements)"
    [[ -f "$requirements" ]] || fail 'PPT Master requirements.txt is missing.'

    apt_install "${module_packages[@]}"
    prepare_uv

    uv venv --python "$(component_ids "$module_components" python-runtime)" "$environment"
    uv pip install --python "$environment/bin/python" --upgrade -r "$requirements"
    uv pip check --python "$environment/bin/python"

    configure_skill_runtime "$installed_skill_directory"
}

show_skill_status() {
    local directory environment

    directory="$(skill_path "${skill_names[0]}")" || directory="$skill_directory/${skill_names[0]}"
    environment="$directory/.venv"

    skill_status "${skill_names[@]}"
    package_status "${module_packages[@]}"
    if [[ -x "$environment/bin/python" ]]; then
        "$environment/bin/python" -c 'import pptx, yaml, PIL, fitz, requests, flask, openpyxl; print("PPT Master Python core imports: available")'
    else
        print_message warning '%s\n' 'PPT Master Python: not-installed'
    fi
}
