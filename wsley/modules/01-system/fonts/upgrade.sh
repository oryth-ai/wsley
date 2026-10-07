#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../lib/common.sh"

load_module_context "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

parse_options "$@"
preflight_module
require_user
confirm "$(describe_action upgrade)"

apt_upgrade "${module_packages[@]}"
upgrade_windows_fonts
