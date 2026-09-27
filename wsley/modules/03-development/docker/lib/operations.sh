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
    require_ubuntu
    require_command systemctl
    [[ -d /run/systemd/system ]] || fail 'Docker requires a running systemd instance.'
    read_docker_proxy
    apt_install ca-certificates curl gnupg
    make_workdir

    download https://download.docker.com/linux/ubuntu/gpg "$work/docker.asc"
    system_backup "$docker_key"
    as_root install -D -m 0644 "$work/docker.asc" "$docker_key"
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
    apt_install "${docker_packages[@]}"

    if command -v nvidia-smi > /dev/null && nvidia-smi -L 2> /dev/null | grep -q '^GPU '; then
        download https://nvidia.github.io/libnvidia-container/gpgkey "$work/nvidia.asc"
        gpg --batch --yes --dearmor -o "$work/nvidia.gpg" "$work/nvidia.asc"
        system_backup "$nvidia_key"
        as_root install -m 0644 "$work/nvidia.gpg" "$nvidia_key"
        download https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list "$work/nvidia.list"
        sed "s#deb https://#deb [signed-by=$nvidia_key] https://#g" "$work/nvidia.list" > "$work/nvidia.sources"
        system_backup "$nvidia_source"
        as_root install -m 0644 "$work/nvidia.sources" "$nvidia_source"
        mapfile -t gpu_packages < <(component_ids "$module_components" apt-nvidia)
        apt_install "${gpu_packages[@]}"
        system_backup /etc/docker/daemon.json
        as_root nvidia-ctk runtime configure --runtime=docker --set-as-default
    fi

    configure_docker_proxy "$work" "$docker_proxy"

    if ((EUID != 0)) && ! id -nG | tr ' ' '\n' | grep -qx docker; then
        as_root usermod -aG docker "$(id -un)"
    fi

    as_root systemctl daemon-reload
    as_root systemctl enable docker
    as_root systemctl restart docker
    printf 'Docker is ready. Log in again if group membership changed.\n'
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
    local active
    local -a gpu_packages

    mapfile -t gpu_packages < <(component_ids "$module_components" apt-nvidia)
    package_status "${docker_packages[@]}" "${gpu_packages[@]}"
    if [[ -d /run/systemd/system ]]; then
        active="$(systemctl is-active docker 2> /dev/null)" || true
        printf '%-28s %s\n' service "${active:-unknown}"
    fi

    configuration_status "$docker_proxy"
}
