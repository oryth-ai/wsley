#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

font_root="$HOME/.local/share/fonts/windows"

sync_windows_fonts() {
    if [[ ! -d /mnt/c/Windows/Fonts ]]; then
        print_message warning 'Windows fonts directory not found: /mnt/c/Windows/Fonts\n'
        return
    fi

    if ! command -v fc-cache > /dev/null; then
        print_message warning 'Fontconfig is not installed. Run wsley install fonts.\n'
        return
    fi

    mkdir -p "$font_root"
    find /mnt/c/Windows/Fonts -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.ttc' -o -iname '*.otf' \) -exec cp -p -u --target-directory="$font_root" -- '{}' +
    fc-cache -f "$font_root"
}

print_windows_fonts_status() {
    local count='-' state=not-installed

    if [[ -d "$font_root" ]]; then
        count="$(find "$font_root" -maxdepth 1 -type f | wc -l) files"
        state=installed
    elif [[ ! -d /mnt/c/Windows/Fonts ]]; then
        state=not-available
    fi

    print_status "$state" '%-16s %-32s %-32s %s\n' windows-fonts "$count" '-' "$state"
}
