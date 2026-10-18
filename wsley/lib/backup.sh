#!/usr/bin/env bash

backup_file() (
    local target="${1:-}" state="${XDG_STATE_HOME:-$HOME/.local/state}/wsley"
    local label directory stage created_at timestamp resolved lock suffix=0

    if ((EUID == 0)); then
        state=/var/lib/wsley
    fi
    if (($# != 1)) || [[ "$state" != /* || "$target" != /* ]]; then
        printf 'Backup requires one absolute path and an absolute state directory.\n' >&2
        return 1
    fi

    target="$(realpath -ms -- "$target")" || return
    label="${target#/}"
    label="${label//\//__}"
    label="${label//[^a-zA-Z0-9._-]/_}"
    if ((${#label} > 96)); then
        label="${label: -96}"
    fi

    umask 077
    mkdir -p -- "$state/backups" || return
    stage="$(mktemp -d "$state/backups/.stage.XXXXXX")" || return
    trap 'rm -rf -- "$stage"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    created_at="$(date --iso-8601=seconds)" || return
    timestamp="$(date --date="$created_at" '+%Y%m%d-%H%M%S')" || return
    printf '%s\n' "$target" > "$stage/path" || return
    printf '%s\n' "$created_at" > "$stage/created_at" || return

    if [[ -L "$target" ]]; then
        readlink -- "$target" > "$stage/link" || return
        if [[ -e "$target" ]]; then
            resolved="$(realpath -e -- "$target")" || return
            printf '%s\n' "$resolved" > "$stage/resolved_path" || return
            cp -a -- "$resolved" "$stage/original" || return
        fi
    elif [[ -e "$target" ]]; then
        cp -a -- "$target" "$stage/original" || return
    else
        touch "$stage/created" || return
    fi

    exec {lock}> "$state/backups/.lock" || return
    flock --exclusive "$lock" || return
    directory="$state/backups/$label--$timestamp"
    while [[ -e "$directory" || -L "$directory" ]]; do
        suffix=$((suffix + 1))
        directory="$state/backups/$label--$timestamp-$suffix"
    done
    mv -T -- "$stage" "$directory" || return
    printf 'Backup saved at %s: %s -> %s\n' "$created_at" "$target" "$directory"
)

system_backup() {
    as_root bash -euc "$(declare -f backup_file); backup_file \"\$1\"" bash "$1"
}
