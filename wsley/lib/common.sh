#!/usr/bin/env bash

if [[ "${WSLEY_COMMON_LOADED:-}" == true ]]; then
    return 0
fi
WSLEY_COMMON_LOADED=true

# shellcheck source=wsley/lib/output.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/output.sh"

set -Eeuo pipefail

# shellcheck disable=SC2154
trap 'result=$?; print_message error "Failed at %s:%s (exit %s).\n" "${BASH_SOURCE[0]:-$0}" "$LINENO" "$result" >&2; exit "$result"' ERR

export LC_ALL=C
# shellcheck source=wsley/assets/environment/path.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../assets/environment/path.sh"

apt_options=()
assume_yes=false

fail() {
    print_message error '%s\n' "$*" >&2
    exit 1
}

parse_options() {
    if (($# == 0)); then
        return
    fi

    if (($# == 1)) && [[ "$1" == --yes || "$1" == -y ]]; then
        assume_yes=true
        apt_options=(-y)
    else
        print_message error 'Only --yes (or -y) is supported.\n' >&2
        exit 2
    fi
}

status_options() {
    if (($#)); then
        print_message error 'Status does not accept options.\n' >&2
        exit 2
    fi
}

confirm() {
    local answer prompt="${2:-Continue?}"

    if [[ "$assume_yes" == true ]]; then
        return
    fi

    [[ -z "${1:-}" ]] || print_message heading '%s\n' "$1"
    print_message warning '%s [Y/n] ' "$prompt" >&2
    if ! read -r answer; then
        print_message warning '\nNo confirmation received; cancelled.\n' >&2
        exit 1
    fi
    if [[ -n "$answer" && "$answer" != y && "$answer" != Y ]]; then
        print_message info 'Cancelled.\n' >&2
        exit 1
    fi
}

as_root() {
    if ((EUID == 0)); then
        "$@"
    else
        sudo -- "$@"
    fi
}

require_command() {
    local name

    for name in "$@"; do
        command -v "$name" > /dev/null || fail "Missing command: $name"
    done
}

require_user() {
    ((EUID != 0)) || fail 'Run this user-level module without sudo.'
}

require_ubuntu() {
    # shellcheck source=/etc/os-release
    source /etc/os-release
    [[ "$ID" == ubuntu ]] || fail 'This module requires Ubuntu.'
}

# shellcheck source=wsley/lib/apt-mirror.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/apt-mirror.sh"

apt_install() {
    local package state
    local -a packages=()

    for package in "$@"; do
        state="$(package_state "$package")"
        if [[ "$state" == missing ]]; then
            packages+=("$package")
        else
            print_message info 'Skipped %s: already installed.\n' "$package"
        fi
    done
    ((${#packages[@]})) || return 0
    run_apt_install --no-upgrade "${packages[@]}"
}

apt_upgrade() {
    local package state
    local -a packages=()

    for package in "$@"; do
        state="$(package_state "$package")"
        if [[ "$state" == installed ]]; then
            packages+=("$package")
        else
            print_message info 'Skipped %s: not installed.\n' "$package"
        fi
    done
    ((${#packages[@]})) || return 0
    run_apt_install --only-upgrade "${packages[@]}"
}

run_apt_install() {
    configure_apt_mirror
    as_root apt update -o APT::Update::Error-Mode=any
    as_root apt install --no-remove "${apt_options[@]}" "$@"
}

installed_package_version() {
    local result state version code

    if ! command -v dpkg-query > /dev/null; then
        print_message error 'Missing command: dpkg-query\n' >&2
        return 2
    fi
    if result="$(dpkg-query -W -f='${db:Status-Status}\t${Version}' "$1" 2> /dev/null)"; then
        IFS=$'\t' read -r state version <<< "$result"
        [[ "$state" == installed ]] || return 1
        printf '%s\n' "$version"
    else
        code=$?
        if ((code != 1)); then
            print_message error 'Package query failed: %s (exit %s).\n' "$1" "$code" >&2
        fi
        return "$code"
    fi
}

package_state() {
    local result

    if installed_package_version "$1" > /dev/null; then
        printf 'installed\n'
    else
        result=$?
        ((result == 1)) || return "$result"
        printf 'missing\n'
    fi
}

package_status() {
    local package version result

    for package in "$@"; do
        if version="$(installed_package_version "$package")"; then
            print_message success '%-28s installed %s\n' "$package" "$version"
        else
            result=$?
            ((result == 1)) || return "$result"
            print_message warning '%-28s not-installed\n' "$package"
        fi
    done
}

download() {
    curl --fail --show-error --location --retry 3 "$1" --output "$2"
}

make_workdir() {
    work="$(mktemp -d)"
    trap 'rm -rf -- "$work"' EXIT
}

backup_file() (
    local target="$1" state="${XDG_STATE_HOME:-$HOME/.local/state}/wsley" key directory stage

    if ((EUID == 0)); then
        state=/var/lib/wsley
    fi
    [[ "$state" == /* && "$target" == /* ]] || {
        printf 'Backup paths must be absolute.\n' >&2
        exit 1
    }

    target="$(realpath -ms -- "$target")"
    key="$(printf '%s' "$target" | sha256sum)"
    directory="$state/backups/${key%% *}"
    [[ ! -d "$directory" ]] || return 0

    mkdir -p -- "$(dirname -- "$target")"
    umask 077
    mkdir -p -- "$state/backups"
    stage="$(mktemp -d "$state/backups/.stage.XXXXXX")"
    trap 'rm -rf -- "$stage"' EXIT
    printf '%s\n' "$target" > "$stage/path"

    if [[ -L "$target" ]]; then
        readlink -- "$target" > "$stage/link"
        if [[ -e "$target" ]]; then
            cp -aL -- "$target" "$stage/original"
        fi
    elif [[ -e "$target" ]]; then
        cp -a -- "$target" "$stage/original"
    else
        touch "$stage/created"
    fi
    mv -T -- "$stage" "$directory"
)

system_backup() {
    as_root bash -euc "$(declare -f backup_file); backup_file \"\$1\"" bash "$1"
}

# shellcheck source=wsley/lib/environment.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/environment.sh"

preflight_module() {
    require_ubuntu
    require_command apt dpkg-query
    require_user
    require_command sudo
}

command_status() {
    local name="$1" executable="$2"
    shift 2

    if [[ ! -x "$executable" ]]; then
        executable="$(command -v "$name" || true)"
    fi
    if [[ -z "$executable" ]]; then
        print_message warning '%s: not-installed\n' "$name"
        return
    fi

    print_message info '%s (%s): ' "$name" "$executable"
    (cd / && "$executable" "$@")
}

service_status() {
    local unit="$1" label="$2" properties key value
    local load='' active='' enabled=''

    if ! command -v systemctl > /dev/null || [[ ! -d /run/systemd/system ]]; then
        print_message warning '%-28s systemd-unavailable\n' "$label service"
        return
    fi
    properties="$(systemctl show "$unit" --property=LoadState --property=ActiveState --property=UnitFileState --no-pager)"
    while IFS='=' read -r key value; do
        case "$key" in
            LoadState) load="$value" ;;
            ActiveState) active="$value" ;;
            UnitFileState) enabled="$value" ;;
        esac
    done <<< "$properties"
    [[ -n "$load" && -n "$active" ]] || fail "Incomplete service status: $unit"
    if [[ "$load" == not-found ]]; then
        print_message warning '%-28s not-installed\n' "$label service"
        return
    fi
    print_status "$active" '%-28s %s\n' "$label service" "$active"
    print_status "${enabled:-unknown}" '%-28s %s\n' "$label startup" "${enabled:-unknown}"
}

configuration_status() {
    local file="$1" expected="${2:-}"

    if [[ ! -f "$file" ]]; then
        print_message warning '%-28s %s\n' configuration "missing: $file"
    elif [[ -n "$expected" ]] && ! grep -Fxq "$expected" "$file"; then
        print_message warning '%-28s %s\n' configuration "custom: $file"
    else
        print_message success '%-28s %s\n' configuration "present: $file"
    fi
}

append_configuration_line() {
    local file="$1" line="$2"

    if grep -Fxq "$line" "$file" 2> /dev/null; then
        return
    fi

    backup_file "$file"
    if [[ -s "$file" && -n "$(tail -c 1 -- "$file")" ]]; then
        printf '\n' >> "$file"
    fi
    printf '%s\n' "$line" >> "$file"
}

# shellcheck source=wsley/lib/components.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/components.sh"

load_module_context() {
    module_directory="$1"
    module_components="$module_directory/components.tsv"
    validate_components "$module_components"
    validate_module_info "$module_directory/module.info"
    # shellcheck disable=SC2034
    mapfile -t module_packages < <(component_ids "$module_components" apt)

    if [[ -r "$module_directory/lib/operations.sh" ]]; then
        # shellcheck disable=SC1091
        source "$module_directory/lib/operations.sh"
    fi
}

describe_action() {
    module_section "$module_directory/module.info" "${1^}"
}
