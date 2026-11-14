#!/usr/bin/env bash

set -euo pipefail

if (($# == 1)) && [[ "$1" == -h || "$1" == --help ]]; then
    cat << 'HELP'
Usage: bash wsley/modules/05-codex-plugins/sidekick/check.sh [options]

Validate Sidekick module sources, metadata and resource references.

Options:
  -h, --help    Show this help message and exit.

Notes:
  Checks local sources without installing dependencies, changing user configuration or using the network.
HELP
    exit 0
fi
if (($#)); then
    printf 'Unknown argument: %s. Run bash %s --help.\n' "$1" "$0" >&2
    exit 2
fi

module_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
/usr/bin/python3 -B "$module_directory/lib/plugin.py" validate "$module_directory"
