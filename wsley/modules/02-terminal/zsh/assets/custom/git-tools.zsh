git-archive() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        if (($# != 1)); then
            print -u2 "git-archive: Help does not accept arguments."
            return 2
        fi
        cat << 'HELP'
Usage: git-archive [options] [<commit>]

Archive a commit as project-vdate-hash.tgz in the current directory.

Arguments:
  <commit>      Commit or reference to archive (default: HEAD).

Options:
  -h, --help    Show this help message and exit.

Examples:
  git-archive HEAD
HELP
        return 0
    fi

    if [[ $# -gt 1 ]]; then
        print -u2 "git-archive: Expected at most one commit. Run git-archive --help."
        return 2
    fi

    local commit="${1:-HEAD}"
    local repo_root resolved_commit project_name commit_date short_commit archive_name archive_path

    repo_root="$(git rev-parse --show-toplevel 2> /dev/null)" || {
        print -u2 "git-archive: The current directory is not a Git repository."
        return 1
    }

    resolved_commit="$(git rev-parse --verify "${commit}^{commit}" 2> /dev/null)" || {
        print -u2 "git-archive: Invalid commit: $commit"
        return 1
    }

    project_name="${repo_root:t}"
    commit_date="$(git show -s --format=%cd --date=format:%Y%m%d "$resolved_commit")" || return 1
    short_commit="$(git rev-parse --short "$resolved_commit")" || return 1
    archive_name="${project_name}-v${commit_date}-${short_commit}.tgz"
    archive_path="${PWD}/${archive_name}"

    git -C "$repo_root" archive \
        --format=tar.gz \
        --output="$archive_path" \
        --prefix="${project_name}/" \
        "$resolved_commit"
}

git-wip() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        if (($# != 1)); then
            print -u2 "git-wip: Help does not accept arguments."
            return 2
        fi
        cat << 'HELP'
Usage: git-wip [options] [<message>]

Stage the current directory and create a chore: WIP commit.

Arguments:
  <message>     Commit message suffix (default: current date and time).

Options:
  -h, --help    Show this help message and exit.

Examples:
  git-wip "Checkpoint before refactoring"
HELP
        return 0
    fi
    if (($# > 1)); then
        print -u2 "git-wip: Expected at most one message. Run git-wip --help."
        return 2
    fi
    local msg="${1:-@ $(date +"%Y-%m-%d %H:%M:%S")}"
    git add . && git commit -m "chore: WIP $msg"
}

git-unwip() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        if (($# != 1)); then
            print -u2 "git-unwip: Help does not accept arguments."
            return 2
        fi
        cat << 'HELP'
Usage: git-unwip [options]

Remove consecutive chore: WIP commits from the tip of the current branch.

Options:
  -h, --help    Show this help message and exit.

Notes:
  Resets to the latest non-WIP first-parent commit using git reset --soft.
  File contents and the staging area are preserved.
HELP
        return 0
    fi
    if (($#)); then
        print -u2 "git-unwip: Arguments are not supported. Run git-unwip --help."
        return 2
    fi
    local head_subject target

    head_subject="$(git log -1 --format=%s)" || return 1
    if [[ "$head_subject" != "chore: WIP"* ]]; then
        print -u2 "git-unwip: HEAD is not a chore: WIP commit."
        return 1
    fi

    target="$(git log --first-parent --format=%H --invert-grep --grep='^chore: WIP' -n 1)" || return 1
    if [[ -z "$target" ]]; then
        print -u2 "git-unwip: No non-WIP commit was found."
        return 1
    fi

    git reset --soft "$target"
}
