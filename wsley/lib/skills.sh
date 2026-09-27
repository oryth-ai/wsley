#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

skill_directory="$HOME/.agents/skills"
codex_skill_directory="${CODEX_HOME:-$HOME/.codex}/skills"

skill_status() {
    local name directory found resolved previous

    for name in "$@"; do
        found=false
        previous=''
        for directory in "$skill_directory" "$codex_skill_directory"; do
            if [[ -f "$directory/$name/SKILL.md" ]]; then
                resolved="$(readlink -f -- "$directory/$name")"
                [[ "$resolved" != "$previous" ]] || continue
                printf '%-30s installed  %s\n' "$name" "$directory/$name"
                found=true
                previous="$resolved"
            fi
            [[ "$skill_directory" != "$codex_skill_directory" ]] || break
        done
        if [[ "$found" == false ]]; then
            printf '%-30s not-installed\n' "$name"
        fi
    done
}

# Keep replacement and rollback in one process, including installer failures.
replace_skill() (
    local name="$1" stage directory candidate='' completed=false codex_link=false result
    shift
    local -a targets=("$skill_directory/$name")

    [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]] || fail "Invalid skill name: $name"
    if [[ "$(readlink -m -- "$skill_directory")" != "$(readlink -m -- "$codex_skill_directory")" ]]; then
        targets+=("$codex_skill_directory/$name")
    fi
    mkdir -p "$skill_directory"
    stage="$(mktemp -d "$skill_directory/.wsley-$name.XXXXXX")"

    # Called by the EXIT trap, including when the installer fails.
    # shellcheck disable=SC2329
    cleanup_skill_replacement() {
        result=$?
        trap - EXIT
        if [[ "$completed" == false ]]; then
            for directory in "${!targets[@]}"; do
                if [[ -f "$stage/started-$directory" ]]; then
                    if [[ -f "$stage/existed-$directory" && ! -e "$stage/previous-$directory" && ! -L "$stage/previous-$directory" ]]; then
                        continue
                    fi
                    if ! rm -rf -- "${targets[$directory]}"; then
                        printf 'Recovery files retained: %s\n' "$stage" >&2
                        exit 1
                    fi
                    if [[ -e "$stage/previous-$directory" || -L "$stage/previous-$directory" ]]; then
                        if ! mv -- "$stage/previous-$directory" "${targets[$directory]}"; then
                            printf 'Recovery files retained: %s\n' "$stage" >&2
                            exit 1
                        fi
                    fi
                fi
            done
        fi
        rm -rf -- "$stage"
        exit "$result"
    }
    trap cleanup_skill_replacement EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    # Snapshot linked copies before moving either of their targets.
    for directory in "${targets[@]}"; do
        backup_file "$directory"
    done
    for directory in "${!targets[@]}"; do
        if [[ -e "${targets[$directory]}" || -L "${targets[$directory]}" ]]; then
            [[ "$directory" == 0 ]] || codex_link=true
            touch "$stage/existed-$directory" "$stage/started-$directory"
            mv -- "${targets[$directory]}" "$stage/previous-$directory"
        else
            touch "$stage/started-$directory"
        fi
    done

    "$@"

    for directory in "${targets[@]}"; do
        [[ -f "$directory/SKILL.md" ]] || continue
        [[ "$directory" == "${targets[0]}" ]] || codex_link=true
        if [[ -n "$candidate" ]]; then
            diff -qr -- "$candidate" "$directory" > /dev/null ||
                fail "Installer produced conflicting skill copies: $name"
        else
            candidate="$directory"
        fi
    done
    [[ -n "$candidate" ]] || fail "Skill installation did not produce SKILL.md: $name"

    mkdir "$stage/new"
    cp -a -- "$candidate/." "$stage/new/"
    for directory in "${targets[@]}"; do
        rm -rf -- "$directory"
    done
    mv -- "$stage/new" "${targets[0]}"
    if [[ "$codex_link" == true && ${#targets[@]} == 2 ]]; then
        mkdir -p "$codex_skill_directory"
        ln -s -- "${targets[0]}" "${targets[1]}"
    fi
    completed=true
    printf 'Installed: %s\n' "$name"
)

copy_bundled_skill() {
    local source_directory="$1" target="$2"

    mkdir -p "$target"
    cp -a -- "$source_directory/." "$target/"
}

install_bundled_skill() {
    local source_directory="$1" name

    name="${source_directory##*/}"
    [[ -f "$source_directory/SKILL.md" ]] || fail "Missing skill definition: $source_directory"
    replace_skill "$name" copy_bundled_skill "$source_directory" "$skill_directory/$name"
}

load_skill_runtime() {
    # shellcheck source=wsley/lib/node.sh
    source "$(dirname -- "${BASH_SOURCE[0]}")/node.sh"
}

preflight_remote_skills() (
    require_ubuntu
    require_user
    require_command apt dpkg-query sudo
    load_skill_runtime
    validate_node_environment
)

run_skill_installer() (
    cd /
    pnpx skills@latest add "$1" --global --agent codex --yes --copy --skill "$2"
)

install_remote_skills() {
    local repository="$1" name="$2"

    [[ $# == 2 ]] || fail 'Install one named skill at a time.'
    load_skill_runtime
    prepare_node
    if ! command -v git > /dev/null; then
        local -a missing_packages=()
        mapfile -t missing_packages < <(component_ids "$module_components" apt-missing)
        apt_install ca-certificates "${missing_packages[@]}"
    fi

    replace_skill "$name" run_skill_installer "$repository" "$name"
    # The caller uses the copy published by this installation.
    # shellcheck disable=SC2034
    installed_skill_directory="$skill_directory/$name"
}

skill_path() {
    local directory

    for directory in "$codex_skill_directory" "$skill_directory"; do
        if [[ -f "$directory/$1/SKILL.md" ]]; then
            printf '%s\n' "$directory/$1"
            return
        fi
    done
    return 1
}
