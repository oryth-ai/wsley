#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../lib/common.sh"

load_module_context "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

status_options "$@"

command_status uv "$HOME/.local/bin/uv" --version
command_status python "$HOME/.local/bin/python" --version

if command -v uv > /dev/null; then
    uv python list --only-installed
fi
