#!/usr/bin/env bash

set -euo pipefail
export LC_ALL=C

root="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"

# shellcheck source=wsley/lib/modules.sh
source "$root/lib/modules.sh"

usage() {
    print_message heading '%s\n' 'Wsley - Ubuntu Development Environment Manager'
    cat << 'HELP'

Usage:
  wsley list [module|group]...
  wsley install <module|group>... [--yes]
  wsley upgrade <module|group>... [--yes]
  wsley status <module|group>...
  wsley self-upgrade [--yes]
  wsley help

Module and group names can be mixed and are case-sensitive.
Install, upgrade and status process each module once, in argument order.
Install adds missing components; upgrade updates installed components.
Run wsley list to see modules and groups, or wsley list <module> for details.
--yes (or -y) skips action confirmation, not APT mirror or Docker proxy questions.
Self-upgrade refreshes the Wsley PATH environment after updating the checkout.
Self-upgrade asks separately before overwriting local changes or diverged history.
Force overwrite defaults to no and is never implied by --yes.
HELP
}

action="${1:-help}"
case "$action" in
    help | -h | --help)
        if (($# > 1)); then
            print_message error 'Help does not accept arguments.\n' >&2
            exit 2
        fi
        usage
        exit 0
        ;;
    self-upgrade)
        # shellcheck source=wsley/lib/self-upgrade.sh
        source "$root/lib/self-upgrade.sh"
        self_upgrade_wsley "$(dirname -- "$root")" "${@:2}"
        exit 0
        ;;
    __complete)
        # shellcheck source=wsley/lib/completion.sh
        source "$root/lib/completion.sh"
        complete_wsley "$root/modules" "${@:2}"
        exit 0
        ;;
    list | install | upgrade | status) ;;
    *)
        print_message error 'Unknown command: %s. Run wsley help.\n' "$action" >&2
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
                print_message error '%s does not accept %s.\n' "$action" "$argument" >&2
                exit 2
            fi
            options=(--yes)
            ;;
        -*)
            print_message error 'Unknown option: %s\n' "$argument" >&2
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
    print_message error 'No module or group specified. Usage: wsley %s <module|group>...\n' "$action" >&2
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
        print_message warning 'No modules selected.\n'
        exit 0
    fi
    action_options=()
else
    parse_options "${options[@]}"
    if ((${#selected_paths[@]} == 0)); then
        print_message error 'No modules to %s.\n' "$action" >&2
        exit 1
    fi
    for index in "${!selected_paths[@]}"; do
        print_message info 'Checking requirements: %s\n' "${selected_ids[$index]}"
        if bash -ec '
            source "$2/lib/common.sh"
            load_module_context "$1"
            preflight_module
        ' bash "${selected_paths[$index]}" "$root"; then
            :
        else
            result=$?
            print_message error 'Requirements check failed: %s. No modules were run.\n' "${selected_ids[$index]}" >&2
            exit "$result"
        fi
    done

    print_message heading '%s modules:\n' "${action^}"
    for index in "${!selected_paths[@]}"; do
        printf '  %s:\n' "${selected_ids[$index]}"
        bash -ec '
            source "$3/lib/components.sh"
            module_section "$1/module.info" "${2^}"
        ' bash "${selected_paths[$index]}" "$action" "$root" | sed 's/^/    /'
    done
    confirm '' 'Proceed with the listed actions?'
    if [[ -z "${WSLEY_APT_STATE:-}" ]]; then
        apt_session="$(mktemp -d)"
        trap 'rm -rf -- "$apt_session"' EXIT
        export WSLEY_APT_STATE="$apt_session/checked"
    fi
    action_options=(--yes)
fi

failed=0
for index in "${!selected_paths[@]}"; do
    print_message heading '\n[%s]\n' "${selected_ids[$index]}"
    if bash "${selected_paths[$index]}/$action.sh" "${action_options[@]}"; then
        if [[ "$action" != status ]]; then
            print_message success 'Completed %s: %s\n' "$action" "${selected_ids[$index]}"
        fi
    else
        result=$?
        print_message error 'Failed: %s (%s, exit %s).\n' "${selected_ids[$index]}" "$action" "$result" >&2
        if [[ "$action" != status ]]; then
            if ((index + 1 < ${#selected_paths[@]})); then
                print_message warning 'Not run:' >&2
                printf ' %s' "${selected_ids[@]:index+1}" >&2
                printf '\n' >&2
            fi
            exit "$result"
        fi
        failed=1
    fi
done
exit "$failed"
