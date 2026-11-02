#!/usr/bin/env bash

# shellcheck source=wsley/lib/modules.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/modules.sh"

complete_wsley() {
    local directory="$1" action prefix='' candidate index word has_yes=false
    local -a candidates=() targets=()
    local -A used=()
    shift

    (($# == 0)) || prefix="${!#}"
    if (($# <= 1)); then
        candidates=(list install upgrade status self-upgrade help --help -h)
    else
        action="$1"
        shift
        for ((index = 1; index < $#; index++)); do
            word="${!index}"
            [[ -n "$word" ]] || continue
            used[$word]=1
            case "$word" in
                --yes | -y) has_yes=true ;;
                --help | -h) return 0 ;;
                *) targets+=("$word") ;;
            esac
        done
        case "$action" in
            list | install | upgrade | status)
                load_modules "$directory" || return
                select_targets "${targets[@]}" || return
                for word in "${selected_ids[@]}"; do
                    used[$word]=1
                done
                for candidate in "${group_ids[@]}"; do
                    candidates+=("${candidate#*-}")
                done
                candidates+=("${module_ids[@]}")
                candidates+=(--help -h)
                if [[ ("$action" == install || "$action" == upgrade) && "$has_yes" == false ]]; then
                    candidates+=(--yes -y)
                fi
                ;;
            self-upgrade)
                candidates=(--help -h)
                [[ "$has_yes" == true ]] || candidates+=(--yes -y)
                ;;
            help)
                (($# <= 1)) || return 0
                candidates=(list install upgrade status self-upgrade help --help -h)
                ;;
        esac
    fi

    for candidate in "${candidates[@]}"; do
        if [[ "$candidate" == "$prefix"* && -z "${used[$candidate]:-}" ]]; then
            printf '%s\n' "$candidate"
        fi
    done
    return 0
}
