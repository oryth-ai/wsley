#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

install_chrome() {
    local state

    state="$(package_state google-chrome-stable)"
    if [[ "$state" == installed ]]; then
        print_message info 'Skipped Chrome: already installed.\n'
        return
    fi
    apply_chrome_package
}

upgrade_chrome() {
    local state

    state="$(package_state google-chrome-stable)"
    if [[ "$state" == missing ]]; then
        print_message info 'Skipped Chrome: not installed.\n'
        return
    fi
    apply_chrome_package
}

apply_chrome_package() {
    [[ "$(dpkg --print-architecture)" == amd64 ]] || fail 'Chrome requires amd64.'
    apt_install ca-certificates curl
    make_workdir
    chmod 0755 "$work"
    curl --fail --show-error --location --retry 5 --retry-delay 2 --retry-all-errors --connect-timeout 15 "$(component_ids "$module_components" deb)" --output "$work/chrome.deb"
    as_root apt install --no-remove "${apt_options[@]}" "$work/chrome.deb"

    [[ -x /opt/google/chrome/chrome ]]
}

preflight_module() {
    require_ubuntu
    require_command apt dpkg-query
    if ((EUID != 0)); then
        require_command sudo
    fi
    [[ "$(dpkg --print-architecture)" == amd64 ]] || fail "Chrome requires amd64."
}
