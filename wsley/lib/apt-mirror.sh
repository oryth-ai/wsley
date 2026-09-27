#!/usr/bin/env bash

configure_apt_mirror() {
    [[ "${apt_mirror_checked:-false}" == false ]] || return 0
    if [[ -n "${WSLEY_APT_STATE:-}" && -f "$WSLEY_APT_STATE" ]]; then
        apt_mirror_checked=true
        return
    fi

    require_ubuntu

    local file answer
    local source_files=()

    for file in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
        [[ -f "$file" ]] || continue
        if process_apt_sources check "$file"; then
            source_files+=("$file")
        fi
    done

    if ((${#source_files[@]})); then
        printf 'Ubuntu official sources are configured.\n'
        read -r -p 'Replace them with the Aliyun mirror? [y/N] ' answer || answer=''
        if [[ "$answer" == y || "$answer" == Y ]]; then
            replace_apt_sources "${source_files[@]}"
        fi
    fi

    apt_mirror_checked=true
    if [[ -n "${WSLEY_APT_STATE:-}" ]]; then
        : > "$WSLEY_APT_STATE"
    fi
}

process_apt_sources() {
    local mode="$1" file="$2" format=list

    [[ "$file" != *.sources ]] || format=deb822
    awk -v mode="$mode" -v format="$format" \
        -f "$(dirname -- "${BASH_SOURCE[0]}")/apt-sources.awk" "$file"
}

replace_apt_sources() (
    local file temporary

    temporary="$(mktemp)"
    trap 'rm -f -- "$temporary"' EXIT

    for file in "$@"; do
        process_apt_sources replace "$file" > "$temporary"
        if ! cmp --silent "$file" "$temporary"; then
            system_backup "$file"
            as_root install -m 0644 "$temporary" "$file"
        fi
    done
)
