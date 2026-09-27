#!/usr/bin/env bash

prepare_uv() {
    local mode="${1:-install}"

    case "$mode" in
        install | upgrade) ;;
        *) fail "Unsupported uv preparation mode: $mode" ;;
    esac

    require_user
    install_user_environment

    if command -v uv > /dev/null; then
        if [[ "$mode" == install ]]; then
            return
        fi
        if uv self update; then
            return
        fi
    fi

    apt_install ca-certificates curl
    curl --fail --show-error --location https://astral.sh/uv/install.sh | sh
    hash -r
    require_command uv
}
