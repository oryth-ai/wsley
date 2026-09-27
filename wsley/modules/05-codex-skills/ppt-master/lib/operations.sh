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
    validate_python_environment
}

validate_python_environment() {
    local environment="$HOME/.local/share/wsley/ppt-master/.venv" expected actual

    [[ -e "$environment" || -L "$environment" ]] || return 0
    [[ -x "$environment/bin/python" ]] || fail "PPT Master Python environment is incomplete: $environment"
    expected="$(component_ids "$module_components" python-runtime)"
    actual="$("$environment/bin/python" -c 'import sys; print("%s.%s" % sys.version_info[:2])')"
    [[ "$actual" == "$expected" ]] ||
        fail "PPT Master requires Python $expected; existing environment uses $actual: $environment. Move it aside before installing."
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
    local requirements environment="$HOME/.local/share/wsley/ppt-master/.venv"

    validate_python_environment
    install_remote_skills "$skill_repository" "${skill_names[@]}"
    requirements="$installed_skill_directory/$(component_ids "$module_components" requirements)"
    [[ -f "$requirements" ]] || fail 'PPT Master requirements.txt is missing.'

    apt_install "${module_packages[@]}"
    prepare_uv

    if [[ ! -x "$environment/bin/python" ]]; then
        uv venv --python "$(component_ids "$module_components" python-runtime)" "$environment"
    fi
    uv pip install --python "$environment/bin/python" --upgrade -r "$requirements"
    uv pip check --python "$environment/bin/python"

    mkdir -p "$HOME/.local/bin"
    backup_file "$HOME/.local/bin/ppt-master-python"
    printf '#!/usr/bin/env bash\nexec %q "$@"\n' "$environment/bin/python" > "$HOME/.local/bin/ppt-master-python"
    chmod +x "$HOME/.local/bin/ppt-master-python"

    configure_skill_runtime "$installed_skill_directory"
}

show_skill_status() {
    local environment="$HOME/.local/share/wsley/ppt-master/.venv"

    skill_status "${skill_names[@]}"
    package_status "${module_packages[@]}"
    if [[ -x "$environment/bin/python" ]]; then
        "$environment/bin/python" -c 'import pptx, yaml, PIL, fitz, requests, flask, openpyxl; print("PPT Master Python core imports: available")'
    else
        printf '%s\n' 'PPT Master Python: not-installed'
    fi
    configuration_status "$HOME/.local/bin/ppt-master-python"
}
