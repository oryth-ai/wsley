#!/usr/bin/env bash

set -euo pipefail

module_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
/usr/bin/python3 -B "$module_directory/lib/plugin.py" validate "$module_directory"
