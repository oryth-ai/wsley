#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

install_libreoffice() {
    apt_install "${module_packages[@]}"
    require_command libreoffice
}

preflight_module() {
    require_ubuntu
    require_command apt dpkg-query
    if ((EUID != 0)); then
        require_command sudo
    fi
}
