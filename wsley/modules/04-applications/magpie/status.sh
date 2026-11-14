#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../lib/common.sh"

status_options "$@"

load_module_context "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

show_magpie_status
