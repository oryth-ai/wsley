#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

# shellcheck source=wsley/lib/node.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/node.sh"

install_codex() {
    if [[ -x "$PNPM_HOME/bin/codex" ]] || command -v codex > /dev/null; then
        print_message info 'Skipped Codex: already installed.\n'
        return
    fi
    apply_codex_package
}

upgrade_codex() {
    if [[ ! -x "$PNPM_HOME/bin/codex" ]] && ! command -v codex > /dev/null; then
        print_message info 'Skipped Codex: not installed.\n'
        return
    fi
    apply_codex_package
}

apply_codex_package() {
    local -a cli_packages=()

    require_user

    prepare_node

    mapfile -t cli_packages < <(component_ids "$module_components" pnpm)
    (cd / && pnpm add --global "${cli_packages[@]}")
    require_command codex

    codex --version
}

preflight_module() {
    require_ubuntu
    require_user
    require_command apt dpkg-query sudo
    validate_node_environment
}
