#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

# shellcheck source=wsley/lib/python.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/python.sh"

install_python() {
    local installed interpreter bin_directory name

    require_user
    install_uv
    installed="$(uv python list --only-installed --managed-python)"
    if [[ -z "$installed" ]]; then
        uv python install --default
        return
    fi
    interpreter="$(uv python find --managed-python --no-project --system --offline --no-python-downloads)"
    bin_directory="$(uv python dir --bin)"
    [[ -x "$interpreter" && "$bin_directory" == /* ]] || fail 'Cannot locate the installed managed Python or executable directory.'
    mkdir -p "$bin_directory"
    for name in python python3; do
        if [[ ! -e "$bin_directory/$name" && ! -L "$bin_directory/$name" ]]; then
            ln -s "$interpreter" "$bin_directory/$name"
        fi
    done
    print_message info 'Python command setup complete.\n'
}

upgrade_python() {
    local installed

    require_user
    if ! command -v uv > /dev/null; then
        print_message info 'Skipped uv and Python: uv is not installed.\n'
        return
    fi
    upgrade_uv
    installed="$(uv python list --only-installed --managed-python)"
    if [[ -n "$installed" ]]; then
        uv python upgrade
    else
        print_message info 'Skipped Python: no uv-managed versions installed.\n'
    fi
}
