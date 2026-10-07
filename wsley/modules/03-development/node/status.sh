#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../lib/common.sh"

load_module_context "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

status_options "$@"

command_status node "$PNPM_HOME/bin/node" --version
command_status pnpm "$PNPM_HOME/bin/pnpm" --version

for name in pnpx npm npx; do
    if command -v "$name" > /dev/null; then
        print_message success '%-10s %s\n' "$name" "$(command -v "$name")"
    else
        print_message warning '%-10s not-installed\n' "$name"
    fi
done
