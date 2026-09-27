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

install_node() {
    local node_catalog temporary

    validate_node_environment
    require_user
    apt_install ca-certificates curl

    if [[ -x "$PNPM_HOME/bin/pnpm" ]]; then
        (cd / && "$PNPM_HOME/bin/pnpm" self-update)
    else
        (
            temporary="$(mktemp)"
            trap 'rm -f -- "$temporary"' EXIT
            # Wsley publishes the shared environment for Bash and Zsh.
            curl --fail --show-error --location https://get.pnpm.io/install.sh |
                env -u BASH_VERSION -u ZSH_VERSION -u FISH_VERSION -u NU_VERSION \
                    SHELL=/bin/sh ENV="$temporary" sh -
        )
    fi

    ln -sfn pnpm "$PNPM_HOME/bin/npm"
    ln -sfn pnpx "$PNPM_HOME/bin/npx"

    hash -r
    require_command pnpm
    node_catalog="$(find_module_directory "$(dirname -- "${BASH_SOURCE[0]}")/../modules" node)/components.tsv"
    validate_components "$node_catalog"
    (cd / && pnpm runtime set node "$(component_ids "$node_catalog" node-runtime)" --global)
    hash -r

    require_command node pnpm pnpx npm npx

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
