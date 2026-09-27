#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

install_ssh() {
    require_ubuntu
    require_command systemctl
    [[ -d /run/systemd/system ]] || fail 'SSH service management requires a running systemd instance.'

    apt_install "${module_packages[@]}"
    as_root systemctl enable --now ssh
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
