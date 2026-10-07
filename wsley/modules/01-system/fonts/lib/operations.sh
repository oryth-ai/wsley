#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

font_root="$HOME/.local/share/fonts/windows"

install_windows_fonts() {
    local source_file target changed=false

    if [[ ! -d /mnt/c/Windows/Fonts ]]; then
        print_message info 'Windows font copy skipped: /mnt/c/Windows/Fonts is not available.\n'
        return
    fi

    while IFS= read -r -d '' source_file; do
        target="$font_root/${source_file##*/}"
        if [[ -e "$target" || -L "$target" ]]; then
            print_message info 'Skipped %s: already installed.\n' "${source_file##*/}"
            continue
        fi
        require_command fc-cache
        mkdir -p "$font_root"
        cp -p -- "$source_file" "$target"
        changed=true
    done < <(find /mnt/c/Windows/Fonts -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.ttc' -o -iname '*.otf' \) -print0)
    if [[ "$changed" == true ]]; then
        fc-cache -f "$font_root"
    fi
}

upgrade_windows_fonts() {
    local source_file target changed=false

    if [[ ! -d /mnt/c/Windows/Fonts ]]; then
        print_message info 'Windows font copy skipped: /mnt/c/Windows/Fonts is not available.\n'
        return
    fi

    while IFS= read -r -d '' source_file; do
        target="$font_root/${source_file##*/}"
        if [[ ! -e "$target" && ! -L "$target" ]]; then
            print_message info 'Skipped %s: not installed.\n' "${source_file##*/}"
            continue
        fi
        require_command fc-cache
        mkdir -p "$font_root"
        cp -p -- "$source_file" "$target"
        changed=true
    done < <(find /mnt/c/Windows/Fonts -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.ttc' -o -iname '*.otf' \) -print0)
    if [[ "$changed" == true ]]; then
        fc-cache -f "$font_root"
    fi
}

print_windows_fonts_status() {
    local count state=not-installed

    if [[ -d "$font_root" ]]; then
        count="$(find "$font_root" -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.ttc' -o -iname '*.otf' \) | wc -l)"
        ((count == 0)) || state=installed
        print_status "$state" '%-28s %s files in %s\n' windows-fonts "$count" "$font_root"
    else
        print_message info '%-28s not-copied\n' windows-fonts
    fi

    if [[ ! -d /mnt/c/Windows/Fonts ]]; then
        print_message info 'Windows font source: unavailable (/mnt/c/Windows/Fonts)\n'
    fi
}
