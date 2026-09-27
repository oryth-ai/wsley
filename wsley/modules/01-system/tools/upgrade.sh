#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../lib/common.sh"

load_module_context "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

parse_options "$@"
preflight_module
require_user
require_apt
confirm "$(describe_action upgrade)"

apt_install ca-certificates curl
configure_github_source
apt_install "${module_packages[@]}"

upgrade_uv_tools
