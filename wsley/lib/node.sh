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
    require_command node pnpm pnpx

    mkdir -p "$PNPM_HOME/bin"
    if [[ ! -e "$PNPM_HOME/bin/npm" && ! -L "$PNPM_HOME/bin/npm" ]]; then
        ln -s "$(command -v pnpm)" "$PNPM_HOME/bin/npm"
    fi
    if [[ ! -e "$PNPM_HOME/bin/npx" && ! -L "$PNPM_HOME/bin/npx" ]]; then
        ln -s "$(command -v pnpx)" "$PNPM_HOME/bin/npx"
    fi
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
        configure_node_environment
    fi
    require_command node pnpm pnpx
}
