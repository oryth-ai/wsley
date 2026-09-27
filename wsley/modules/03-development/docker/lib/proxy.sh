#!/usr/bin/env bash

read_docker_proxy() {
    local port
    docker_proxy_url=''

    print_message info 'Configure an HTTP proxy for the Docker service at 127.0.0.1.\n'
    while true; do
        print_message warning 'Proxy port (leave empty to keep proxy configuration unchanged): ' >&2
        read -r port || port=''
        [[ -n "$port" ]] || return 0

        if [[ "$port" =~ ^[0-9]{1,5}$ ]] && ((10#$port >= 1 && 10#$port <= 65535)); then
            break
        fi
        print_message warning 'Enter a port between 1 and 65535, or leave empty to skip.\n' >&2
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
