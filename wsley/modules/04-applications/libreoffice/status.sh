#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../lib/common.sh"

load_module_context "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

status_options "$@"

package_status libreoffice libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-draw libreoffice-base libreoffice-math
