#!/usr/bin/env bash

validate_components() {
    [[ -r "$1" ]] || {
        printf 'Missing component catalog: %s\n' "$1" >&2
        return 1
    }
    awk -F '\t' '
        NR == 1 {
            if ($0 != "group\tmanager\tid\tdescription") exit 1
            next
        }
        NF != 4 || /\r/ { exit 1 }
        {
            for (i = 1; i <= 4; i++) if ($i !~ /[^[:space:]]/) exit 1
            if ($2 !~ /^(apt|apt-missing|apt-nvidia|uv-tool|pnpm|skill|bundled|runtime|python-runtime|node-runtime|git|asset|config|deb|requirements)$/) exit 1
            if (seen[$2 SUBSEP $3]++) exit 1
            if ($1 != previous && groups[$1]++) exit 1
            previous = $1
        }
        END { if (NR < 2) exit 1 }
    ' "$1" || {
        printf 'Invalid component catalog: %s\n' "$1" >&2
        return 1
    }
}

component_ids() {
    local file="$1" manager="$2" group="${3:-}"

    awk -F '\t' -v manager="$manager" -v group="$group" \
        'NR > 1 && $2 == manager && (group == "" || $1 == group) {print $3}' "$file"
}

component_groups() {
    awk -F '\t' 'NR > 1 && !seen[$1]++ {print $1}' "$1"
}

show_components() {
    local file="$1" group manager id description index item prefix branch
    local -a groups=() rows=()

    mapfile -t groups < <(component_groups "$file")
    printf '\nComponents:\n'
    for index in "${!groups[@]}"; do
        group="${groups[$index]}"
        branch='├──' prefix='│   '
        if ((index == ${#groups[@]} - 1)); then
            branch='└──' prefix='    '
        fi
        printf '%s %s\n' "$branch" "$group"
        mapfile -t rows < <(awk -F '\t' -v group="$group" 'NR > 1 && $1 == group' "$file")
        for item in "${!rows[@]}"; do
            # shellcheck disable=SC2034
            IFS=$'\t' read -r group manager id description <<< "${rows[$item]}"
            branch='├──'
            ((item != ${#rows[@]} - 1)) || branch='└──'
            printf '%s%s %s [%s]\n' "$prefix" "$branch" "$description" "$manager"
        done
    done
}

module_section() {
    local file="$1" section="$2"

    awk -v heading="$section:" '
        /^[A-Za-z]+:$/ { active = ($0 == heading); next }
        active && /^  / { sub(/^  /, ""); print }
    ' "$file"
}

validate_module_info() {
    [[ -r "$1" ]] || {
        printf 'Missing module description: %s\n' "$1" >&2
        return 1
    }
    awk '
        BEGIN {
            split("Install Upgrade Status Requirements Configuration", headings, " ")
        }
        NR == 1 { if ($0 !~ /[^[:space:]]/ || /[\r\t]/) exit 1; next }
        /^$/ { next }
        /^[A-Za-z]+:$/ {
            if (section && !body) exit 1
            section++
            if ($0 != headings[section] ":") exit 1
            body = 0
            next
        }
        /^  [^[:space:]]/ && section { body++; next }
        { exit 1 }
        END { if (section != 5 || !body) exit 1 }
    ' "$1" || {
        printf 'Invalid module description: %s\n' "$1" >&2
        return 1
    }
}
