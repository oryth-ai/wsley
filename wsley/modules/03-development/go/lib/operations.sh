#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

go_root="$HOME/.local/share/go"

install_go() (
    local go_arch metadata archive_info archive checksum version version_dir
    local current_link="$go_root/current" bin_dir="$HOME/.local/bin"
    local temporary command_name command_link go_environment

    require_user
    install_user_environment
    apt_install "${module_packages[@]}"
    go_arch="$(dpkg --print-architecture)"

    temporary="$(mktemp -d)"
    trap 'rm -rf -- "$temporary"' EXIT
    metadata="$temporary/releases.json"
    download 'https://go.dev/dl/?mode=json' "$metadata"

    # Select a stable Linux archive without depending on JSON field order or layout.
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
    for command_name in go gofmt; do
        command_link="$bin_dir/$command_name"
        if [[ -e "$command_link" && ! -L "$command_link" ]]; then
            fail "Go command path is not a symbolic link: $command_link"
        fi
    done

    if [[ ! -x "$version_dir/bin/go" ]]; then
        download "https://go.dev/dl/$archive" "$temporary/$archive"
        printf '%s  %s\n' "$checksum" "$temporary/$archive" | sha256sum --check --status
        tar -C "$temporary" -xzf "$temporary/$archive"
        mkdir -p "$go_root"
        mv "$temporary/go" "$version_dir"
    fi

    ln -sfn "$version_dir" "$current_link"
    mkdir -p "$bin_dir"
    for command_name in go gofmt; do
        ln -sfn "$current_link/bin/$command_name" "$bin_dir/$command_name"
    done

    export PATH="$bin_dir:$PATH"
    go_environment="$(go env GOENV)"
    [[ "$go_environment" != off ]] || fail 'GOENV=off prevents persistent GOBIN configuration.'
    backup_file "$go_environment"
    go env -w GOBIN="$bin_dir"
    go version
)

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
