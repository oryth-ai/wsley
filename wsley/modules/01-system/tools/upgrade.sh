#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../lib/common.sh"

parse_options "$@"

load_module_context "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
preflight_module
require_user
require_apt
confirm "$(describe_action upgrade)"

apt_upgrade "${module_packages[@]}"

upgrade_uv_tools
