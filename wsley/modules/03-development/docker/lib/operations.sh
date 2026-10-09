#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

# shellcheck source=wsley/modules/03-development/docker/lib/proxy.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/proxy.sh"

docker_packages=("${module_packages[@]}")
docker_source=/etc/apt/sources.list.d/docker.sources
docker_key=/etc/apt/keyrings/docker.asc
nvidia_source=/etc/apt/sources.list.d/nvidia-container-toolkit.list
nvidia_key=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
docker_proxy=/etc/systemd/system/docker.service.d/wsley-proxy.conf

install_docker() {
    local engine_state package state docker_user user_groups
    local missing_engine_package=false gpu_state=missing
    local -a gpu_packages=()

    require_ubuntu
    require_command systemctl
    [[ -d /run/systemd/system ]] || fail 'Docker requires a running systemd instance.'
    mapfile -t gpu_packages < <(component_ids "$module_components" apt-nvidia)

    engine_state="$(package_state docker-ce)"
    for package in "${docker_packages[@]}"; do
        state="$(package_state "$package")"
        [[ "$state" != missing ]] || missing_engine_package=true
    done

    if [[ "$missing_engine_package" == true ]]; then
        apt_install ca-certificates curl gnupg
        make_workdir
        if [[ ! -e "$docker_key" && ! -L "$docker_key" ]]; then
            download https://download.docker.com/linux/ubuntu/gpg "$work/docker.asc"
            system_backup "$docker_key"
            as_root install -D -m 0644 "$work/docker.asc" "$docker_key"
        fi
        if [[ ! -e "$docker_source" && ! -L "$docker_source" ]]; then
            cat > "$work/docker.sources" << EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: $docker_key
EOF
            system_backup "$docker_source"
            as_root install -m 0644 "$work/docker.sources" "$docker_source"
        fi
    fi
    apt_install "${docker_packages[@]}"

    if command -v nvidia-smi > /dev/null && nvidia-smi -L 2> /dev/null | grep -q '^GPU '; then
        gpu_state="$(package_state nvidia-container-toolkit)"
        if [[ "$gpu_state" == missing ]]; then
            apt_install ca-certificates curl gnupg
            [[ -n "${work:-}" ]] || make_workdir
            if [[ ! -e "$nvidia_key" && ! -L "$nvidia_key" ]]; then
                download https://nvidia.github.io/libnvidia-container/gpgkey "$work/nvidia.asc"
                gpg --batch --yes --dearmor -o "$work/nvidia.gpg" "$work/nvidia.asc"
                system_backup "$nvidia_key"
                as_root install -D -m 0644 "$work/nvidia.gpg" "$nvidia_key"
            fi
            if [[ ! -e "$nvidia_source" && ! -L "$nvidia_source" ]]; then
                download https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list "$work/nvidia.list"
                sed "s#deb https://#deb [signed-by=$nvidia_key] https://#g" "$work/nvidia.list" > "$work/nvidia.sources"
                system_backup "$nvidia_source"
                as_root install -m 0644 "$work/nvidia.sources" "$nvidia_source"
            fi
            apt_install "${gpu_packages[@]}"
            if [[ ! -e /etc/docker/daemon.json && ! -L /etc/docker/daemon.json ]]; then
                system_backup /etc/docker/daemon.json
                as_root nvidia-ctk runtime configure --runtime=docker --set-as-default
            fi
        fi
    fi

    docker_user="$(id -un)"
    if ((EUID == 0)); then
        docker_user="${SUDO_USER:-root}"
    fi
    if [[ "$docker_user" != root ]]; then
        user_groups="$(id -nG -- "$docker_user")"
        if [[ " $user_groups " != *" docker "* ]]; then
            as_root usermod -aG docker "$docker_user"
            print_message info 'Docker group membership updated for %s. Log out and back in to use it in your shell.\n' "$docker_user"
        fi
    fi

    if [[ "$engine_state" == installed ]]; then
        print_message info 'Docker service settings preserved.\n'
        return
    fi
    if [[ ! -e "$docker_proxy" && ! -L "$docker_proxy" ]]; then
        read_docker_proxy
        configure_docker_proxy "$work" "$docker_proxy"
    fi
    as_root systemctl daemon-reload
    as_root systemctl enable docker
    as_root systemctl restart docker
    print_message success 'Docker service enabled and restarted.\n'
}

upgrade_docker() {
    local -a gpu_packages=()

    mapfile -t gpu_packages < <(component_ids "$module_components" apt-nvidia)
    apt_upgrade "${docker_packages[@]}" "${gpu_packages[@]}"
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

show_docker_status() {
    local -a gpu_packages

    mapfile -t gpu_packages < <(component_ids "$module_components" apt-nvidia)
    package_status "${docker_packages[@]}" "${gpu_packages[@]}"
    service_status docker Docker

    if [[ -f "$docker_proxy" ]]; then
        print_message info '%-28s configured: %s\n' 'Wsley Docker proxy' "$docker_proxy"
    else
        print_message info '%-28s not-configured (optional)\n' 'Wsley Docker proxy'
    fi
}
