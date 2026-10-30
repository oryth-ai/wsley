#!/usr/bin/env bash

backup_file() (
    local target="${1:-}" state="$HOME/.local/state/wsley"
    local label destination timestamp lock suffix=0

    if ((EUID == 0)); then
        state=/var/lib/wsley
    fi
    if (($# != 1)) || [[ "$state" != /* || "$target" != /* ]]; then
        printf 'Backup requires one absolute path and an absolute state directory.\n' >&2
        return 1
    fi

    target="$(realpath -ms -- "$target")" || return
    [[ -e "$target" || -L "$target" ]] || return 0

    label="${target#/}"
    label="${label//\//__}"
    label="${label//[^a-zA-Z0-9._-]/_}"
    if ((${#label} > 96)); then
        label="${label: -96}"
    fi

    umask 077
    mkdir -p -- "$state/backups" || return
    timestamp="$(date '+%Y%m%d-%H%M%S%z')" || return
    exec {lock}> "$state/backups/.lock" || return
    flock --exclusive "$lock" || return
    destination="$state/backups/$label--$timestamp"
    while [[ -e "$destination" || -L "$destination" ]]; do
        suffix=$((suffix + 1))
        destination="$state/backups/$label--$timestamp-$suffix"
    done

    trap 'rm -rf -- "$destination"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    cp -a -- "$target" "$destination" || return
    trap - EXIT
    printf 'Backup saved: %s -> %s\n' "$target" "$destination"
)

system_backup() {
    as_root bash -euc "$(declare -f backup_file); backup_file \"\$1\"" bash "$1"
}

replace_file() (
    local source_file="$1" target="$2" mode="${3:-}" temporary

    if [[ ! -f "$source_file" || "$target" != /* || (-e "$target" && ! -f "$target") ]]; then
        printf 'File replacement requires a regular source and an absolute file target: %s\n' "$target" >&2
        return 1
    fi
    if [[ -z "$mode" && -f "$target" ]]; then
        mode="$(stat -Lc '%a' -- "$target")" || return
    fi
    if [[ -n "$mode" ]]; then
        [[ "$mode" =~ ^[0-7]{1,4}$ ]] || {
            printf 'Invalid replacement file mode: %s\n' "$mode" >&2
            return 1
        }
        mode="$(printf '%o' "$((8#$mode))")"
    fi
    if cmp -s -- "$source_file" "$target" &&
        [[ -z "$mode" || "$(stat -Lc '%a' -- "$target")" == "$mode" ]]; then
        return
    fi

    mkdir -p -- "$(dirname -- "$target")" || return
    temporary="$(mktemp "$(dirname -- "$target")/.wsley-file.XXXXXX")" || return
    trap 'rm -f -- "$temporary"' EXIT
    cp --preserve=mode,timestamps -- "$source_file" "$temporary" || return
    if [[ -n "$mode" ]]; then
        chmod "$mode" "$temporary" || return
    fi
    backup_file "$target" || return
    mv -Tf -- "$temporary" "$target"
)

system_replace_file() {
    as_root bash -euc "$(declare -f backup_file replace_file); replace_file \"\$@\"" bash "$@"
}

replace_link() (
    local source_file="$1" target="$2" temporary

    if [[ "$target" != /* || (-d "$target" && ! -L "$target") ]]; then
        printf 'Link replacement requires an absolute non-directory target: %s\n' "$target" >&2
        return 1
    fi
    if [[ -L "$target" && "$(readlink -- "$target")" == "$source_file" ]]; then
        return
    fi
    mkdir -p -- "$(dirname -- "$target")" || return
    temporary="$(mktemp -d "$(dirname -- "$target")/.wsley-link.XXXXXX")" || return
    trap 'rm -rf -- "$temporary"' EXIT
    ln -s -- "$source_file" "$temporary/link" || return
    backup_file "$target" || return
    mv -Tf -- "$temporary/link" "$target"
)
