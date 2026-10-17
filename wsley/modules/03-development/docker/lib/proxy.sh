#!/usr/bin/env bash

docker_proxy=/etc/systemd/system/docker.service.d/wsley-proxy.conf
docker_proxy_socket=/etc/systemd/system/wsley-docker-proxy.socket
docker_proxy_service=/etc/systemd/system/wsley-docker-proxy.service

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

read_docker_proxy_relay() {
    local answer
    docker_proxy_relay_requested=false

    print_message heading 'Optional container proxy relay\n'
    print_message info '%s\n' \
        'Containers cannot directly use a host proxy that listens only on 127.0.0.1.' \
        'Choose yes if your containers need to use that local proxy.' \
        'The relay listens on the Docker bridge at 172.17.0.1:7897 and forwards requests to the local proxy port configured for Docker.' \
        'Choose no if containers can already reach your proxy on the Docker bridge address or 0.0.0.0:7897, or if containers do not need a proxy.' \
        'Choosing yes installs and starts a systemd socket and enables it at boot. The upstream proxy application must run separately.' \
        'In containers, set HTTP_PROXY and HTTPS_PROXY to http://host.docker.internal:7897 and add host.docker.internal:host-gateway using --add-host or Compose extra_hosts.' \
        'Choosing no skips the relay and keeps the Docker daemon proxy configuration.'
    while true; do
        print_message warning 'Install the container proxy relay? [y/N] ' >&2
        if ! read -r answer; then
            print_message warning '\nNo relay choice received; installation cancelled.\n' >&2
            return 1
        fi
        case "${answer,,}" in
            y | yes)
                docker_proxy_relay_requested=true
                return 0
                ;;
            '' | n | no) return 0 ;;
            *) print_message warning 'Enter y to install the relay, or n / Enter to skip it.\n' >&2 ;;
        esac
    done
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

refresh_docker_proxy_relay() {
    local module_directory="$1" port socket_active=false service_active=false

    [[ -x /usr/lib/systemd/systemd-socket-proxyd ]] || fail 'Missing executable: /usr/lib/systemd/systemd-socket-proxyd'
    port="$(as_root sed -n 's|^Environment="HTTP_PROXY=http://127\.0\.0\.1:\([0-9]\{1,5\}\)"$|\1|p' "$docker_proxy")"
    if [[ ! "$port" =~ ^[0-9]{1,5}$ ]] || ((10#$port < 1 || 10#$port > 65535)); then
        fail "Expected HTTP_PROXY=http://127.0.0.1:<port> in $docker_proxy."
    fi

    [[ -n "${work:-}" ]] || make_workdir
    sed "s/@PROXY_PORT@/$((10#$port))/g" "$module_directory/assets/wsley-docker-proxy.service.in" > "$work/wsley-docker-proxy.service"
    if as_root cmp -s "$module_directory/assets/wsley-docker-proxy.socket" "$docker_proxy_socket" &&
        as_root cmp -s "$work/wsley-docker-proxy.service" "$docker_proxy_service"; then
        return
    fi

    if systemctl is-active --quiet wsley-docker-proxy.socket; then
        socket_active=true
    fi
    if systemctl is-active --quiet wsley-docker-proxy.service; then
        service_active=true
    fi

    system_backup "$docker_proxy_socket"
    system_backup "$docker_proxy_service"
    as_root install -D -m 0644 "$module_directory/assets/wsley-docker-proxy.socket" "$docker_proxy_socket"
    as_root install -D -m 0644 "$work/wsley-docker-proxy.service" "$docker_proxy_service"

    if [[ "$socket_active" == true || "$service_active" == true ]]; then
        as_root systemctl stop wsley-docker-proxy.service wsley-docker-proxy.socket
    fi
    as_root systemctl daemon-reload
    if [[ "$socket_active" == true ]]; then
        as_root systemctl start wsley-docker-proxy.socket
    fi
    if [[ "$service_active" == true ]]; then
        as_root systemctl start wsley-docker-proxy.service
    fi
}

install_docker_proxy() {
    local module_directory="$1" relay_installed=false configure_proxy=false

    if [[ ! -e "$docker_proxy" && ! -L "$docker_proxy" ]]; then
        read_docker_proxy
        [[ -n "$docker_proxy_url" ]] || return 0
        configure_proxy=true
    fi

    if [[ -e "$docker_proxy_socket" || -L "$docker_proxy_socket" || -e "$docker_proxy_service" || -L "$docker_proxy_service" ]]; then
        relay_installed=true
    else
        read_docker_proxy_relay
    fi

    if [[ "$configure_proxy" == true ]]; then
        [[ -n "${work:-}" ]] || make_workdir
        configure_docker_proxy "$work" "$docker_proxy"
    fi
    if [[ "$relay_installed" == false && "$docker_proxy_relay_requested" == false ]]; then
        print_message info 'Container proxy relay skipped. Docker daemon proxy configuration retained.\n'
        return 0
    fi
    refresh_docker_proxy_relay "$module_directory"
    if [[ "$relay_installed" == false ]]; then
        as_root systemctl enable --now wsley-docker-proxy.socket
    fi
    print_message info 'Default container proxy endpoint: http://host.docker.internal:7897 (host-gateway mapping required).\n'
}
