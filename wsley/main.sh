#!/usr/bin/env bash

set -euo pipefail
export LC_ALL=C

root="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"

# shellcheck source=wsley/lib/modules.sh
source "$root/lib/modules.sh"

usage() {
    cat << 'HELP'
Wsley - Ubuntu environment management

Usage:
  wsley list [module|group]
  wsley install <module|group> [--yes]
  wsley upgrade <module|group> [--yes]
  wsley status <module|group>
  wsley update [--yes]

Names are case-sensitive. Run wsley list to see available targets.
--yes (or -y) skips action confirmation, not APT or proxy questions.
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
    list | install | upgrade | status) ;;
    *)
        usage >&2
        exit 2
        ;;
esac

load_modules "$root/modules"
if [[ "$action" == list && $# == 1 ]]; then
    list_modules
    exit 0
fi

[[ $# -ge 2 ]] || {
    usage >&2
    exit 2
}
select_target "$2"
shift 2

if [[ "$action" == list ]]; then
    [[ $# == 0 ]] || {
        usage >&2
        exit 2
    }
    if [[ "$target_kind" == module ]]; then
        show_module "${selected_ids[0]}"
    else
        list_modules "$selected_group"
    fi
    exit 0
fi

# shellcheck source=wsley/lib/common.sh
source "$root/lib/common.sh"
if [[ "$action" == status ]]; then
    status_options "$@"
    if ((${#selected_paths[@]} == 0)); then
        printf '%s: no modules.\n' "$selected_group"
        exit 0
    fi
    action_options=()
else
    parse_options "$@"
    if ((${#selected_paths[@]} == 0)); then
        printf 'No modules to %s in group: %s\n' "$action" "$selected_group" >&2
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

    printf '%s targets:\n' "${action^}"
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
