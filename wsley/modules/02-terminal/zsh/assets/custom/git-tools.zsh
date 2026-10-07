git-archive() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        print "Usage: git-archive [commit]"
        print "Description: Archive a commit as project-vdate-hash.tgz; default: HEAD."
        return 0
    fi

    if [[ $# -gt 1 ]]; then
        print -u2 "Usage: git-archive [commit]"
        return 1
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
    local msg="${1:-@ $(date +"%Y-%m-%d %H:%M:%S")}"
    git add . && git commit -m "chore: WIP $msg"
}

git-unwip() {
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
