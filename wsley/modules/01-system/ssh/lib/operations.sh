#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

install_ssh() {
    local server_state

    server_state="$(package_state openssh-server)"
    apt_install "${module_packages[@]}"
    if [[ "$server_state" == missing ]]; then
        require_command systemctl
        [[ -d /run/systemd/system ]] || fail 'SSH service management requires a running systemd instance.'
        as_root systemctl enable --now ssh
    fi
}

upgrade_ssh() {
    apt_upgrade "${module_packages[@]}"
}

preflight_module() {
    require_ubuntu
    require_command apt dpkg-query
    if ((EUID != 0)); then
        require_command sudo
    fi
    require_command systemctl
    [[ -d /run/systemd/system ]] || fail "This module requires a running systemd instance."
}
