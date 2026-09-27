#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

update_wsley() {
    local repository="$1" top branch upstream
    shift

    parse_options "$@"
    require_command git

    top="$(git -C "$repository" rev-parse --show-toplevel 2> /dev/null)" ||
        fail 'Self-update requires a Git checkout. Run the Wsley installer.'
    [[ "$(readlink -f -- "$top")" == "$repository" ]] ||
        fail 'The Wsley directory must be the Git repository root.'
    branch="$(git -C "$repository" symbolic-ref --quiet --short HEAD)" ||
        fail 'Self-update requires a checked-out branch, not a detached HEAD.'
    upstream="$(git -C "$repository" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2> /dev/null)" ||
        fail 'The current branch has no upstream. Configure its tracking branch first.'
    [[ -z "$(git -C "$repository" status --porcelain --untracked-files=all)" ]] ||
        fail 'The Wsley checkout has local changes. Commit or move them before updating.'

    confirm "Update Wsley at $repository ($branch from $upstream)?"

    # Replace this process before Git updates the scripts on disk.
    exec git -C "$repository" -c merge.autoStash=false -c rebase.autoStash=false pull --ff-only --no-rebase
}
