#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../lib/common.sh"

load_module_context "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

status_options "$@"

for name in node pnpm pnpx npm npx; do
    if command -v "$name" > /dev/null; then
        printf '%-10s %s\n' "$name" "$(command -v "$name")"
    else
        printf '%-10s not-installed\n' "$name"
    fi
done

if command -v node > /dev/null; then
    node --version
fi

if [[ -x "$PNPM_HOME/bin/pnpm" ]]; then
    (cd / && "$PNPM_HOME/bin/pnpm" --version)
fi
