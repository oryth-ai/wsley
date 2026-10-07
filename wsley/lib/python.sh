#!/usr/bin/env bash

install_uv() {
    require_user
    install_user_environment
    if command -v uv > /dev/null; then
        return
    fi
    apt_install ca-certificates curl
    curl --fail --show-error --location https://astral.sh/uv/install.sh |
        env UV_INSTALL_DIR="$HOME/.local/bin" UV_NO_MODIFY_PATH=1 sh
    hash -r
    require_command uv
}

upgrade_uv() {
    require_user
    if ! command -v uv > /dev/null; then
        print_message info 'Skipped uv: not installed.\n'
        return
    fi
    install_user_environment
    uv self update
}
