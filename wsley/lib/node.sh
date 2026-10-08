#!/usr/bin/env bash

# shellcheck source=wsley/lib/modules.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/modules.sh"

if [[ -z "${PNPM_HOME:-}" && -r "$HOME/.config/wsley/environment/node.sh" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.config/wsley/environment/node.sh"
fi

# shellcheck source=wsley/assets/environment/node.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../assets/environment/node.sh"

configure_node_environment() (
    local temporary quoted_home

    validate_node_environment
    install_user_environment
    temporary="$(mktemp)"
    trap 'rm -f -- "$temporary"' EXIT
    quoted_home="$(printf '%s' "$PNPM_HOME" | sed "s/'/'\\\\''/g")"
    printf "export PNPM_HOME='%s'\n" "$quoted_home" > "$temporary"
    sed '/^export PNPM_HOME=/d' "$(dirname -- "${BASH_SOURCE[0]}")/../assets/environment/node.sh" >> "$temporary"
    install_environment node "$temporary"
)

managed_pnpm_path() {
    local candidate
    for candidate in "$PNPM_HOME/bin/pnpm" "$PNPM_HOME/pnpm"; do
        if [[ -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return
        fi
    done
    return 1
}

set_node_runtime() {
    local pnpm_command="$1" node_catalog

    node_catalog="$(find_module_directory "$(dirname -- "${BASH_SOURCE[0]}")/../modules" node)/components.tsv"
    validate_components "$node_catalog"
    (cd / && "$pnpm_command" runtime set node "$(component_ids "$node_catalog" node-runtime)" --global)
    hash -r
}

node_command_outside_bin() (
    local name="$1" directory remaining="$PATH:"
    local -a directories=()

    while [[ -n "$remaining" ]]; do
        directory="${remaining%%:*}"
        remaining="${remaining#*:}"
        [[ "$directory" == "$PNPM_HOME/bin" ]] || directories+=("$directory")
    done
    local IFS=:
    PATH="${directories[*]}"
    command -v "$name"
)

configure_node_commands() {
    local name target executable

    require_command pnpm
    mkdir -p "$PNPM_HOME/bin"
    if ! command -v pnpx > /dev/null; then
        target="$PNPM_HOME/bin/pnpx"
        [[ ! -e "$target" && ! -L "$target" ]] || fail "Cannot create pnpx: $target already exists but is not executable."
        backup_file "$target"
        # shellcheck disable=SC2016
        printf '#!/bin/sh\nexec pnpm dlx "$@"\n' > "$target"
        chmod 0755 "$target"
        hash -r
    fi
    require_command pnpx

    for name in npm npx; do
        target="$PNPM_HOME/bin/$name"
        executable="$(command -v pnpm)"
        [[ "$name" != npx ]] || executable="$(command -v pnpx)"
        if [[ -L "$target" && "$(readlink -f -- "$target")" == "$(readlink -f -- "$executable")" ]] &&
            node_command_outside_bin "$name" > /dev/null; then
            backup_file "$target"
            rm -- "$target"
            hash -r
        fi
        if ! command -v "$name" > /dev/null && [[ ! -e "$target" && ! -L "$target" ]]; then
            backup_file "$target"
            ln -s -- "$executable" "$target"
            hash -r
        fi
    done
}

install_node() {
    local pnpm_command temporary

    validate_node_environment
    require_user
    if ! command -v pnpm > /dev/null; then
        apt_install ca-certificates curl
        (
            temporary="$(mktemp)"
            trap 'rm -f -- "$temporary"' EXIT
            curl --fail --show-error --location https://get.pnpm.io/install.sh |
                env -u BASH_VERSION -u ZSH_VERSION -u FISH_VERSION -u NU_VERSION \
                    SHELL=/bin/sh ENV="$temporary" sh -
        )
        hash -r
    fi
    require_command pnpm
    pnpm_command="$(managed_pnpm_path || command -v pnpm)"
    if ! command -v node > /dev/null; then
        set_node_runtime "$pnpm_command"
    fi
    configure_node_commands
    require_command node pnpm pnpx
    configure_node_environment
}

upgrade_node() {
    local pnpm_command='' managed_node=false

    validate_node_environment
    require_user
    [[ -x "$PNPM_HOME/bin/node" || -x "$PNPM_HOME/node" ]] && managed_node=true
    if pnpm_command="$(managed_pnpm_path)"; then
        (cd / && "$pnpm_command" self-update)
    else
        print_message info 'Skipped pnpm: not installed under PNPM_HOME.\n'
        if [[ "$managed_node" == false ]]; then
            print_message info 'Skipped Node.js: not installed under PNPM_HOME.\n'
            return
        fi
        if ! pnpm_command="$(command -v pnpm)"; then
            print_message info 'Skipped Node.js: pnpm is unavailable.\n'
            return
        fi
    fi
    if [[ "$managed_node" == true ]]; then
        set_node_runtime "$pnpm_command"
    else
        print_message info 'Skipped Node.js: not installed under PNPM_HOME.\n'
    fi
    configure_node_commands
    configure_node_environment
}

validate_node_environment() {
    [[ "$PNPM_HOME" == /* && "$PNPM_HOME" != *$'\n'* && "$PNPM_HOME" != *$'\r'* && "$PNPM_HOME" != *:* ]] ||
        fail 'PNPM_HOME must be an absolute, single-line path without colons.'
}

prepare_node() {
    validate_node_environment
    if ! command -v node > /dev/null || ! command -v pnpm > /dev/null || ! command -v pnpx > /dev/null; then
        install_node
    else
        configure_node_commands
        configure_node_environment
    fi
    require_command node pnpm pnpx
}
