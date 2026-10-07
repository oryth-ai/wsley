#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

self_upgrade_wsley() {
    local repository="$1" top branch upstream remote merge_ref target changes result answer
    shift

    parse_options "$@"
    require_command git

    top="$(git -C "$repository" rev-parse --show-toplevel 2> /dev/null)" ||
        fail 'Self-upgrade requires a Git checkout. Run the Wsley installer.'
    [[ "$(readlink -f -- "$top")" == "$repository" ]] ||
        fail 'The Wsley directory must be the Git repository root.'
    branch="$(git -C "$repository" symbolic-ref --quiet --short HEAD)" ||
        fail 'Self-upgrade requires a checked-out branch, not a detached HEAD.'
    upstream="$(git -C "$repository" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2> /dev/null)" ||
        fail 'The current branch has no upstream. Configure its tracking branch first.'
    remote="$(git -C "$repository" config --get "branch.$branch.remote")"
    merge_ref="$(git -C "$repository" config --get-all "branch.$branch.merge")"
    [[ "$merge_ref" == refs/heads/* && "$merge_ref" != *$'\n'* ]] ||
        fail 'Self-upgrade requires a single upstream branch.'

    print_message heading 'Upgrade Wsley: %s (%s from %s)\n' "$repository" "$branch" "$upstream"
    confirm '' 'Proceed with the self-upgrade?'

    git -C "$repository" fetch --no-tags -- "$remote" "$merge_ref" ||
        fail 'Could not fetch the upstream branch. The local checkout was not changed.'
    target="$(git -C "$repository" rev-parse --verify 'FETCH_HEAD^{commit}')"
    changes="$(git -C "$repository" status --porcelain --untracked-files=all)"

    if git -C "$repository" merge-base --is-ancestor HEAD "$target"; then
        if [[ -z "$changes" ]]; then
            git -C "$repository" -c merge.autoStash=false merge --ff-only --no-edit --no-overwrite-ignore "$target"
            install_user_environment
            return
        fi
    else
        result=$?
        ((result == 1)) || fail 'Could not compare local and upstream history.'
        print_message warning 'Local history differs from %s (local commits or rewritten upstream history).\n' "$upstream" >&2
    fi

    if [[ -n "$changes" ]]; then
        print_message warning 'Local changes:\n%s\n' "$changes" >&2
    fi
    print_message warning 'Force overwrite will reset %s to %s (%s).\n' "$branch" "$upstream" "$target" >&2
    print_message warning 'Local commits and tracked changes will be discarded; untracked or ignored paths blocking upstream files may be overwritten.\n' >&2
    print_message warning 'Force overwrite? [y/N] ' >&2
    if ! read -r answer; then
        print_message info '\nNo confirmation received; cancelled.\n' >&2
        return 1
    fi
    case "$answer" in
        y | Y | yes | YES) ;;
        *)
            print_message info 'Cancelled.\n' >&2
            return 1
            ;;
    esac

    git -C "$repository" reset --hard "$target"
    install_user_environment
}
