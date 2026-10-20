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
