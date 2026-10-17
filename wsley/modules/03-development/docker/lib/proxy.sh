#!/usr/bin/env bash

docker_proxy=/etc/systemd/system/docker.service.d/wsley-proxy.conf

read_docker_proxy() {
    local port
    docker_proxy_url=''

    print_message info 'Optional local HTTP proxy for the Docker daemon at 127.0.0.1.\n'
    print_message info 'Docker uses this proxy for image pulls. Container proxy access is configured separately.\n'
    while true; do
        print_message warning 'Proxy port (default: 7897; enter 0 to skip): ' >&2
        read -r port || return 1
        port="${port:-7897}"
        [[ "$port" != 0 ]] || return 0

        if [[ "$port" =~ ^[0-9]{1,5}$ ]] && ((10#$port >= 1 && 10#$port <= 65535)); then
            break
        fi
        print_message warning 'Enter a port between 1 and 65535, 0 to skip, or leave empty for 7897.\n' >&2
    done

    docker_proxy_url="http://127.0.0.1:$((10#$port))"
}

configure_docker_proxy() {
    local work="$1" docker_proxy="$2"

    [[ -n "$docker_proxy_url" ]] || return 0
    cat > "$work/proxy.conf" << EOF
[Service]
Environment="HTTP_PROXY=$docker_proxy_url"
Environment="HTTPS_PROXY=$docker_proxy_url"
Environment="NO_PROXY=localhost,127.0.0.1,::1,host.docker.internal,*.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
EOF
    system_backup "$docker_proxy"
    as_root install -D -m 0600 "$work/proxy.conf" "$docker_proxy"
}

install_docker_proxy() {
    if [[ -e "$docker_proxy" || -L "$docker_proxy" ]]; then
        return 0
    fi

    read_docker_proxy
    [[ -n "$docker_proxy_url" ]] || return 0

    [[ -n "${work:-}" ]] || make_workdir
    configure_docker_proxy "$work" "$docker_proxy"
}
