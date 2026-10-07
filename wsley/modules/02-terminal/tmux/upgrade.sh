#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../lib/common.sh"

load_module_context "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

parse_options "$@"
preflight_module

confirm "$(describe_action upgrade)"

apt_upgrade "${module_packages[@]}"
if [[ -e "$HOME/.tmux.conf" || -L "$HOME/.tmux.conf" ]]; then
    append_configuration_line "$HOME/.tmux.conf" 'set -g mouse on'
fi
