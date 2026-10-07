#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

go_root="$HOME/.local/share/go"

restore_go_commands() {
    local name target bin_directory="$HOME/.local/bin"

    mkdir -p "$bin_directory"
    for name in go gofmt; do
        [[ -x "$go_root/current/bin/$name" ]] || fail "Incomplete Go toolchain: $go_root/current/bin/$name is missing or not executable."
    done
    for name in go gofmt; do
        target="$bin_directory/$name"
        if [[ ! -e "$target" && ! -L "$target" ]]; then
            ln -s "$go_root/current/bin/$name" "$target"
        fi
    done
}

publish_go_release() (
    local go_arch metadata archive_info archive checksum version version_dir temporary
    local current_link="$go_root/current"

    go_arch="$(dpkg --print-architecture)"

    temporary="$(mktemp -d)"
    trap 'rm -rf -- "$temporary"' EXIT
    metadata="$temporary/releases.json"
    download 'https://go.dev/dl/?mode=json' "$metadata"

    archive_info="$(jq -er --arg arch "$go_arch" '
        first(.[] | select(.stable == true) | .files[] |
            select(.os == "linux" and .arch == $arch and .kind == "archive")) |
        [.filename, .sha256] | @tsv
    ' "$metadata")"
    IFS=$'\t' read -r archive checksum <<< "$archive_info"
    [[ "$archive" =~ ^go[0-9]+\.[0-9]+(\.[0-9]+)?\.linux-(amd64|arm64)\.tar\.gz$ &&
        "$checksum" =~ ^[[:xdigit:]]{64}$ ]] || fail 'Invalid Go archive metadata.'

    version="${archive%%.linux-*}"
    version_dir="$go_root/$version"
    if [[ -e "$version_dir" && (! -x "$version_dir/bin/go" || ! -x "$version_dir/bin/gofmt") ]]; then
        fail "Go installation directory is incomplete: $version_dir"
    fi
    if [[ -e "$current_link" && ! -L "$current_link" ]]; then
        fail "Go current path is not a symbolic link: $current_link"
    fi

    if [[ ! -x "$version_dir/bin/go" ]]; then
        download "https://go.dev/dl/$archive" "$temporary/$archive"
        printf '%s  %s\n' "$checksum" "$temporary/$archive" | sha256sum --check --status
        tar -C "$temporary" -xzf "$temporary/$archive"
        mkdir -p "$go_root"
        mv "$temporary/go" "$version_dir"
    fi

    ln -sfn "$version_dir" "$current_link"
    restore_go_commands

)

install_go() {
    local go_environment bin_dir="$HOME/.local/bin"

    require_user
    if [[ -x "$go_root/current/bin/go" ]]; then
        restore_go_commands
        print_message info 'Go toolchain ready.\n'
        return
    fi
    install_user_environment
    apt_install "${module_packages[@]}"
    publish_go_release
    go_environment="$("$go_root/current/bin/go" env GOENV)"
    [[ "$go_environment" != off ]] || fail 'GOENV=off prevents persistent Go configuration.'
    if [[ -z "$("$go_root/current/bin/go" env GOBIN)" ]]; then
        backup_file "$go_environment"
        "$go_root/current/bin/go" env -w GOBIN="$bin_dir"
    fi
    "$go_root/current/bin/go" version
}

upgrade_go() {
    require_user
    if [[ ! -x "$go_root/current/bin/go" ]]; then
        print_message info 'Skipped Go: not installed.\n'
        return
    fi
    install_user_environment
    apt_install "${module_packages[@]}"
    publish_go_release
    "$go_root/current/bin/go" version
}

preflight_module() {
    require_ubuntu
    require_user
    require_command apt dpkg-query sudo
    case "$(dpkg --print-architecture)" in
        amd64 | arm64) ;;
        *) fail 'Go requires amd64 or arm64.' ;;
    esac
    [[ "${GOENV:-}" != off ]] || fail 'GOENV=off prevents persistent GOBIN configuration.'
}

show_go_status() {
    command_status go "$go_root/current/bin/go" version
}
