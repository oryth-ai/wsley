#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

magpie_executable="$HOME/.local/bin/magpie"
magpie_service="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/magpie.service"

preflight_module() {
    require_ubuntu
    require_user
    require_command apt dpkg-query sudo systemctl loginctl timeout
    case "$(dpkg --print-architecture)" in
        amd64 | arm64) ;;
        *) fail 'Magpie requires amd64 or arm64.' ;;
    esac
    [[ "${XDG_CONFIG_HOME:-$HOME/.config}" == /* ]] || fail 'XDG_CONFIG_HOME must be an absolute path.'
    [[ -d /run/systemd/system ]] || fail 'Magpie autostart requires systemd; enable systemd first when using WSL.'
    systemctl --user show-environment > /dev/null || fail 'Magpie autostart requires an accessible systemd user manager; run from a normal user login.'
}

publish_magpie_release() (
    local temporary

    temporary="$(mktemp -d)"
    trap 'rm -rf -- "$temporary"' EXIT
    print_message info 'Downloading the current Magpie terminal release...\n'
    download "$(component_ids "$module_components" asset)" "$temporary/install.sh"
    MAGPIE_BIN_DIR="$temporary/bin" sh "$temporary/install.sh" --tui
    [[ -x "$temporary/bin/magpie" ]] || fail 'The Magpie installer did not produce an executable.'
    replace_file "$temporary/bin/magpie" "$magpie_executable" 0755
)

configure_magpie_service() {
    local user linger

    user="$(id -un)"
    linger="$(loginctl show-user "$user" --property=Linger --value)"
    case "$linger" in
        yes) ;;
        no) as_root loginctl enable-linger "$user" ;;
        *) fail 'Cannot determine whether user lingering is enabled.' ;;
    esac

    backup_file "$magpie_service"
    "$magpie_executable" daemon install --no-web
    systemctl --user is-enabled --quiet magpie.service
    systemctl --user is-active --quiet magpie.service
    timeout 15s "$magpie_executable" daemon status
}

install_magpie() {
    if [[ -x "$magpie_executable" ]]; then
        print_message info 'Skipped Magpie executable: already installed.\n'
    else
        apt_install "${module_packages[@]}"
        publish_magpie_release
    fi
    configure_magpie_service
    "$magpie_executable" --version
}

upgrade_magpie() {
    if [[ ! -x "$magpie_executable" ]]; then
        print_message info 'Skipped Magpie: not installed.\n'
        return
    fi
    apt_install "${module_packages[@]}"
    publish_magpie_release
    configure_magpie_service
    "$magpie_executable" --version
}

show_magpie_status() {
    local linger

    if [[ ! -x "$magpie_executable" ]]; then
        print_message warning 'Magpie: not-installed\n'
        return
    fi
    print_message info 'Magpie executable: %s\n' "$magpie_executable"
    timeout 5s "$magpie_executable" --version
    if [[ ! -d /run/systemd/system ]] || ! systemctl --user show-environment > /dev/null 2>&1; then
        print_message warning 'Magpie service: systemd user manager unavailable\n'
        return
    fi
    timeout 15s "$magpie_executable" daemon status
    linger="$(loginctl show-user "$(id -un)" --property=Linger --value)"
    print_message info 'User lingering: %s\n' "$linger"
}
