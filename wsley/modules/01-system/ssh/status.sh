#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../lib/common.sh"

load_module_context "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

status_options "$@"
package_status "${module_packages[@]}"

if command -v systemctl > /dev/null && [[ -d /run/systemd/system ]]; then
    active="$(systemctl is-active ssh 2> /dev/null)" || true
    enabled="$(systemctl is-enabled ssh 2> /dev/null)" || true
    print_status "${active:-unknown}" '%-28s %s\n' 'SSH service' "${active:-unknown}"
    print_status "${enabled:-unknown}" '%-28s %s\n' 'SSH startup' "${enabled:-unknown}"
else
    print_message warning '%-28s %s\n' 'SSH service' 'systemd-unavailable'
fi
