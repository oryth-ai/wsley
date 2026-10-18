#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

# shellcheck source=wsley/lib/skills.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/skills.sh"

skill_name="$(component_ids "$module_components" bundled)"
skill_assets="$module_directory/assets/$skill_name"
codex_configuration="${CODEX_HOME:-$HOME/.codex}/config.toml"
skill_instructions='Read and follow the coherent-change skill before changing code, configuration, or scripts. After context compaction or a handoff, reread it and resume unfinished work.'

preflight_module() {
    require_user
    require_command awk chmod cmp cp mv mktemp readlink
    [[ -r "$skill_assets/SKILL.md" ]] || fail 'Missing bundled skill: coherent-change'
    [[ "$codex_configuration" == /* ]] || fail 'CODEX_HOME must be an absolute path.'
    if [[ -f "$codex_configuration" ]]; then
        process_codex_configuration replace "$codex_configuration" > /dev/null
    fi
}

process_codex_configuration() {
    awk -v mode="$1" -v instruction="$skill_instructions" \
        -f "$module_directory/lib/codex-config.awk" "$2"
}

configure_codex() (
    local target directory input=/dev/null temporary

    target="$(readlink -m -- "$codex_configuration")"
    [[ ! -e "$target" || -f "$target" ]] || fail "Not a regular configuration file: $codex_configuration"
    directory="$(dirname -- "$target")"
    mkdir -p -- "$directory"
    temporary="$(mktemp "$directory/.wsley-coherent-change.XXXXXX")"
    trap 'rm -f -- "$temporary"' EXIT

    [[ ! -f "$target" ]] || input="$target"
    process_codex_configuration replace "$input" > "$temporary"
    if cmp -s -- "$temporary" "$target"; then
        print_message info 'Skipped Codex developer instructions: already configured.\n'
        return 0
    fi

    backup_file "$codex_configuration" || return
    if [[ -f "$target" ]]; then
        chmod --reference="$target" "$temporary"
    fi
    mv -- "$temporary" "$target"
    print_message success 'Codex developer instructions configured: %s\n' "$codex_configuration"
)

install_skill() {
    install_bundled_skill "$skill_assets"
    configure_codex
}

upgrade_skill() {
    upgrade_bundled_skill "$skill_assets"
    if skill_path "$skill_name" > /dev/null; then
        configure_codex
    fi
}

show_skill_status() {
    skill_status "$skill_name"
    if [[ ! -f "$codex_configuration" ]]; then
        print_message warning '%-30s missing  %s\n' 'Codex developer instructions' "$codex_configuration"
    elif process_codex_configuration check "$codex_configuration"; then
        print_message success '%-30s configured  %s\n' 'Codex developer instructions' "$codex_configuration"
    else
        print_message warning '%-30s custom  %s\n' 'Codex developer instructions' "$codex_configuration"
    fi
}
