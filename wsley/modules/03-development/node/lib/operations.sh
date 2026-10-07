#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

# shellcheck source=wsley/lib/node.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/node.sh"

preflight_module() {
    require_ubuntu
    require_user
    require_command apt dpkg-query sudo
    validate_node_environment
}
