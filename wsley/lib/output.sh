#!/usr/bin/env bash

# Inspect the destination on each call so redirected output stays plain.
print_message() {
    local style="$1" color=''
    shift

    if [[ -t 1 && "${TERM:-dumb}" != dumb && -z "${NO_COLOR+x}" ]]; then
        case "$style" in
            heading) color='1;34' ;;
            info) color=36 ;;
            success) color=32 ;;
            warning) color=33 ;;
            error) color='1;31' ;;
            muted) color=2 ;;
        esac
    fi

    [[ -z "$color" ]] || printf '\033[%sm' "$color"
    # shellcheck disable=SC2059
    printf "$@"
    [[ -z "$color" ]] || printf '\033[0m'
    return 0
}

print_status() {
    local state="$1" style=warning
    shift

    case "$state" in
        installed | active | enabled | current | present) style=success ;;
        failed | error) style=error ;;
    esac
    print_message "$style" "$@"
}
