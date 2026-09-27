#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../lib/common.sh"

load_module_context "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if (($#)); then
    print_message error '%s\n' 'Usage: wsley status tools' >&2
    exit 2
fi

require_apt

print_group() {
    local group="$1" package installed policy candidate state
    shift

    print_message heading '\n[%s]\n' "$group"

    for package in "$@"; do
        installed="$(installed_package_version "$package")" || installed='-'
        policy="$(apt-cache policy "$package")"
        candidate="$(awk '/^[[:space:]]*Candidate:/ {print $2; exit}' <<< "$policy")"
        if [[ -z "$candidate" || "$candidate" == '(none)' ]]; then
            candidate='-'
        fi

        if [[ "$installed" == '-' ]]; then
            state='not-installed'
        elif [[ "$candidate" == '-' ]]; then
            state='no-candidate'
        elif dpkg --compare-versions "$candidate" gt "$installed"; then
            state='upgradable'
        else
            state='installed'
        fi

        print_status "$state" '%-16s %-32s %-32s %s\n' "$package" "$installed" "$candidate" "$state"
    done
}

print_uv_tools() {
    local tool version state

    for tool in "$@"; do
        if version="$(uv_tool_version "$tool")"; then
            state=installed
        else
            version='-'
            state=not-installed
        fi
        print_status "$state" '%-16s %-32s %-32s %s\n' "$tool" "$version" '-' "$state"
    done
}

load_uv_tools

print_message heading '%-16s %-32s %-32s %s\n' PACKAGE INSTALLED CANDIDATE STATUS
while IFS= read -r group; do
    mapfile -t group_packages < <(component_ids "$module_components" apt "$group")
    mapfile -t group_tools < <(component_ids "$module_components" uv-tool "$group")
    print_group "$group" "${group_packages[@]}"
    print_uv_tools "${group_tools[@]}"
done < <(component_groups "$module_components")

print_message muted '\n%s\n' 'APT candidates come from the local index. uv tools show installed versions only.'
