#!/usr/bin/env bash

install_link() {
    local source_file="$1" target="$2"

    [[ ! -d "$target" || -L "$target" ]] || fail "Installation path is a directory: $target"
    if [[ -L "$target" && "$(readlink -- "$target")" == "$source_file" ]]; then
        return
    fi
    mkdir -p -- "$(dirname -- "$target")"
    backup_file "$target"
    ln -sfnT -- "$source_file" "$target"
}

install_wsley() (
    set -euo pipefail

    (($# == 0)) || {
        printf '%s\n' 'The installer does not accept arguments.' >&2
        exit 2
    }
    ((EUID != 0)) || {
        printf '%s\n' 'Run the installer without sudo.' >&2
        exit 1
    }

    local repository=https://github.com/oryth-ai/wsley.git
    local data_directory="${XDG_DATA_HOME:-$HOME/.local/share}"
    local install_directory root top stage=''

    [[ "$data_directory" == /* ]] || {
        printf '%s\n' 'XDG_DATA_HOME must be an absolute path.' >&2
        exit 1
    }
    install_directory="$data_directory/wsley"
    trap '[[ -z "$stage" ]] || rm -rf -- "$stage"' EXIT

    if ! command -v git > /dev/null; then
        if ! command -v sudo > /dev/null || ! command -v apt > /dev/null; then
            printf '%s\n' 'Install Git before running the installer.' >&2
            exit 1
        fi
        sudo apt update -o APT::Update::Error-Mode=any
        sudo apt install --no-remove -y ca-certificates git
    fi

    if [[ -e "$install_directory" || -L "$install_directory" ]]; then
        top="$(git -C "$install_directory" rev-parse --show-toplevel 2> /dev/null)" || {
            printf 'Installation path is not a Git checkout: %s\n' "$install_directory" >&2
            exit 1
        }
        if [[ "$(readlink -f -- "$top")" != "$(readlink -f -- "$install_directory")" ||
        "$(git -C "$install_directory" remote get-url origin)" != "$repository" ||
        "$(git -C "$install_directory" symbolic-ref --quiet --short HEAD)" != main ]]; then
            printf 'Installation requires the Wsley repository on main: %s\n' "$install_directory" >&2
            exit 1
        fi
        [[ -z "$(git -C "$install_directory" status --porcelain --untracked-files=all)" ]] || {
            printf 'The installation has local changes: %s\n' "$install_directory" >&2
            exit 1
        }
        git -C "$install_directory" -c merge.autoStash=false -c rebase.autoStash=false pull --ff-only --no-rebase origin main
    else
        mkdir -p -- "$data_directory"
        stage="$(mktemp -d "$data_directory/.wsley-install.XXXXXX")"
        git clone --branch main --single-branch "$repository" "$stage/repository"
        mv -T -- "$stage/repository" "$install_directory"
    fi

    root="$install_directory/wsley"
    # shellcheck source=wsley/lib/common.sh
    source "$root/lib/common.sh"

    install_link "$root/cli.sh" "$HOME/.local/bin/wsley"
    install_link "$root/assets/completions/bash.sh" "$data_directory/bash-completion/completions/wsley"
    install_link "$root/assets/completions/zsh.zsh" "$data_directory/zsh/site-functions/_wsley"
    install_link "$root/assets/shell/bash.sh" "$HOME/.config/wsley/shell/bash.sh"
    install_link "$root/assets/shell/zsh.zsh" "$HOME/.config/wsley/shell/zsh.zsh"
    install_user_environment

    printf '%s\n' 'Wsley and shell completions installed. Open a new terminal to use them.'
)

install_wsley "$@"
