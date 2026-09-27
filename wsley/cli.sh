#!/usr/bin/env bash

set -euo pipefail
export LC_ALL=C

root="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"

# shellcheck source=wsley/lib/modules.sh
source "$root/lib/modules.sh"

usage() {
    cat << 'HELP'
Wsley - Ubuntu Development Environment Manager

Usage:
  wsley list [module|group]...
  wsley install <module|group>... [--yes]
  wsley upgrade <module|group>... [--yes]
  wsley status <module|group>...
  wsley update [--yes]
  wsley help

Module and group names can be mixed and are case-sensitive.
Install, upgrade and status process each module once, in argument order.
Run wsley list to see available modules and groups.
--yes (or -y) skips action confirmation, not APT mirror or Docker proxy questions.
HELP
}

action="${1:-help}"
case "$action" in
    help | -h | --help)
        usage
        exit 0
        ;;
    update)
        # shellcheck source=wsley/lib/update.sh
        source "$root/lib/update.sh"
        update_wsley "$(dirname -- "$root")" "${@:2}"
        ;;
    __complete)
        # shellcheck source=wsley/lib/completion.sh
        source "$root/lib/completion.sh"
        complete_wsley "$root/modules" "${@:2}"
        exit 0
        ;;
    list | install | upgrade | status) ;;
    *)
        usage >&2
        exit 2
        ;;
esac

shift
targets=()
options=()
for argument in "$@"; do
    case "$argument" in
        --yes | -y)
            if [[ "$action" != install && "$action" != upgrade ]]; then
                printf '%s does not accept %s.\n' "$action" "$argument" >&2
                exit 2
            fi
            options=(--yes)
            ;;
        -*)
            printf 'Unknown option: %s\n' "$argument" >&2
            exit 2
            ;;
        *) targets+=("$argument") ;;
    esac
done

load_modules "$root/modules"
if [[ "$action" == list && ${#targets[@]} == 0 ]]; then
    list_modules
    exit 0
fi
((${#targets[@]})) || {
    usage >&2
    exit 2
}
select_targets "${targets[@]}"

if [[ "$action" == list ]]; then
    if ((${#selected_groups[@]})); then
        list_modules "${selected_groups[@]}"
    fi
    for index in "${!selected_details[@]}"; do
        if ((index > 0 || ${#selected_groups[@]} > 0)); then
            printf '\n'
        fi
        show_module "${selected_details[$index]}"
    done
    exit 0
fi

# shellcheck source=wsley/lib/common.sh
source "$root/lib/common.sh"
if [[ "$action" == status ]]; then
    if ((${#selected_paths[@]} == 0)); then
        printf 'No modules selected.\n'
        exit 0
    fi
    action_options=()
else
    parse_options "${options[@]}"
    if ((${#selected_paths[@]} == 0)); then
        printf 'No modules to %s.\n' "$action" >&2
        exit 1
    fi
    for index in "${!selected_paths[@]}"; do
        printf 'Checking %s...\n' "${selected_ids[$index]}"
        bash -ec '
            source "$2/lib/common.sh"
            load_module_context "$1"
            preflight_module
        ' bash "${selected_paths[$index]}" "$root"
    done

    printf '%s modules:\n' "${action^}"
    for index in "${!selected_paths[@]}"; do
        printf '  %s: ' "${selected_ids[$index]}"
        bash -ec '
            source "$3/lib/components.sh"
            module_section "$1/module.info" "${2^}"
        ' bash "${selected_paths[$index]}" "$action" "$root"
    done
    confirm 'Proceed with all listed modules?'
    if [[ -z "${WSLEY_APT_STATE:-}" ]]; then
        apt_session="$(mktemp -d)"
        trap 'rm -rf -- "$apt_session"' EXIT
        export WSLEY_APT_STATE="$apt_session/checked"
    fi
    action_options=(--yes)
fi

failed=0
for index in "${!selected_paths[@]}"; do
    printf '\n[%s]\n' "${selected_ids[$index]}"
    if bash "${selected_paths[$index]}/$action.sh" "${action_options[@]}"; then
        if [[ "$action" != status ]]; then
            printf 'Completed: %s\n' "${selected_ids[$index]}"
        fi
    else
        result=$?
        printf 'Failed: %s (%s, exit %s).\n' "${selected_ids[$index]}" "$action" "$result" >&2
        if [[ "$action" != status ]]; then
            printf 'Remaining modules were not run.\n' >&2
            exit "$result"
        fi
        failed=1
    fi
done
exit "$failed"
