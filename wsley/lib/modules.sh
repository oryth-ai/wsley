#!/usr/bin/env bash

# shellcheck source=wsley/lib/components.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/components.sh"

find_module_directory() {
    local root="$1" name="$2" directory found=''

    [[ "$name" =~ ^[a-z][a-z0-9-]*$ ]] || return 2
    for directory in "$root"/*/"$name"; do
        [[ -d "$directory" ]] || continue
        if [[ -n "$found" ]]; then
            printf 'Duplicate module name: %s\n' "$name" >&2
            return 1
        fi
        found="$directory"
    done

    if [[ -z "$found" ]]; then
        printf 'Missing module: %s\n' "$name" >&2
        return 1
    fi
    printf '%s\n' "$found"
}

load_modules() {
    local root="$1" directory id group description action group_id
    local -A seen_groups=()
    local -A seen=()

    group_ids=()
    module_ids=()
    module_paths=()
    module_groups=()
    module_descriptions=()

    for directory in "$root"/*; do
        [[ -d "$directory" ]] || continue
        group="${directory##*/}"
        group_id="${group#*-}"
        if [[ ! "$group" =~ ^[0-9]{2}-[a-z][a-z0-9-]*$ ]]; then
            printf 'Invalid group directory: %s\n' "$directory" >&2
            return 1
        fi
        if [[ -n "${seen_groups[$group_id]:-}" ]]; then
            printf 'Duplicate group name: %s\n' "$group_id" >&2
            return 1
        fi
        seen_groups[$group_id]=1
        group_ids+=("$group")
    done

    for directory in "$root"/*/*; do
        [[ -d "$directory" ]] || continue
        id="${directory##*/}"
        group="${directory%/*}"
        group="${group##*/}"

        if [[ ! "$group" =~ ^[0-9]{2}-[a-z][a-z0-9-]*$ || ! "$id" =~ ^[a-z][a-z0-9-]*$ ]]; then
            printf 'Invalid module directory: %s\n' "$directory" >&2
            return 1
        fi

        if [[ -n "${seen[$id]:-}" ]]; then
            printf 'Duplicate module name: %s\n' "$id" >&2
            return 1
        fi

        if [[ ! -r "$directory/module.info" ]]; then
            printf 'Missing module.info: %s\n' "$directory" >&2
            return 1
        fi
        description=''
        IFS= read -r description < "$directory/module.info" || true
        if [[ ! "$description" =~ [^[:space:]] || "$description" == *$'\r'* || "$description" == *$'\t'* ]]; then
            printf 'module.info must start with a nonempty single-line summary: %s\n' "$directory" >&2
            return 1
        fi

        for action in install upgrade status; do
            if [[ ! -f "$directory/$action.sh" || ! -r "$directory/$action.sh" ]]; then
                printf 'Missing module script: %s/%s.sh\n' "$directory" "$action" >&2
                return 1
            fi
        done

        validate_components "$directory/components.tsv" || return 1
        validate_module_info "$directory/module.info" || return 1

        seen[$id]=1
        module_ids+=("$id")
        module_paths+=("$directory")
        module_groups+=("$group")
        module_descriptions+=("$description")
    done
}

list_modules() {
    local index group branch printed=false count name
    local -A filters=()

    for name in "$@"; do
        filters[$name]=1
    done

    if ((${#group_ids[@]} == 0)); then
        printf 'No groups available.\n'
        return
    fi

    for group in "${group_ids[@]}"; do
        [[ $# == 0 || -n "${filters[${group#*-}]:-}" ]] || continue
        [[ "$printed" == false ]] || printf '\n'
        printed=true
        printf '%s (group)\n' "${group#*-}"
        count=0

        for index in "${!module_ids[@]}"; do
            [[ "${module_groups[$index]}" == "$group" ]] || continue
            branch='├──'
            if [[ "${module_groups[$((index + 1))]:-}" != "$group" ]]; then
                branch='└──'
            fi
            printf '%s %-18s %s\n' "$branch" "${module_ids[$index]}" "${module_descriptions[$index]}"
            count=$((count + 1))
        done

        if ((count == 0)); then
            printf '└── (no modules)\n'
        fi
    done

    printf '\n%s\n%s\n' 'Install: wsley install <target>...' 'Details: wsley list <target>...'
}

module_path() {
    local name="$1" index

    for index in "${!module_ids[@]}"; do
        if [[ "${module_ids[$index]}" == "$name" ]]; then
            printf '%s\n' "${module_paths[$index]}"
            return 0
        fi
    done

    printf 'Unknown module: %s. Run wsley list.\n' "$name" >&2
    return 2
}

show_module() {
    local name="$1" directory

    directory="$(module_path "$name")" || return "$?"
    printf '%s - ' "$name"
    head -n 1 "$directory/module.info"
    show_components "$directory/components.tsv"
    tail -n +2 "$directory/module.info"
}

# Selection results are consumed by cli.sh in request order.
# shellcheck disable=SC2034
select_targets() {
    local name index group module_index group_exists
    local -A seen_modules=() seen_targets=()

    selected_paths=()
    selected_ids=()
    selected_groups=()
    selected_details=()

    for name in "$@"; do
        if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
            printf 'Invalid module or group name: %s\n' "$name" >&2
            return 2
        fi
        [[ -z "${seen_targets[$name]:-}" ]] || continue
        module_index=''
        group_exists=false

        for group in "${group_ids[@]}"; do
            if [[ "${group#*-}" == "$name" ]]; then
                group_exists=true
                break
            fi
        done
        for index in "${!module_ids[@]}"; do
            if [[ "${module_ids[$index]}" == "$name" ]]; then
                module_index="$index"
                break
            fi
        done

        if [[ -n "$module_index" && "$group_exists" == true ]]; then
            printf 'Ambiguous module and group name: %s\n' "$name" >&2
            return 2
        elif [[ -z "$module_index" && "$group_exists" == false ]]; then
            printf 'Unknown module or group: %s. Run wsley list.\n' "$name" >&2
            return 2
        fi

        seen_targets[$name]=1
        if [[ -n "$module_index" ]]; then
            selected_details+=("$name")
        else
            selected_groups+=("$name")
        fi
        for index in "${!module_ids[@]}"; do
            if [[ "$index" != "$module_index" && "${module_groups[$index]#*-}" != "$name" ]]; then
                continue
            fi
            [[ -z "${seen_modules[${module_ids[$index]}]:-}" ]] || continue
            seen_modules[${module_ids[$index]}]=1
            selected_ids+=("${module_ids[$index]}")
            selected_paths+=("${module_paths[$index]}")
        done
    done
}
