#!/usr/bin/env bash

docker_daemon=/etc/docker/daemon.json
docker_gc_rule='{"all":true,"reservedSpace":"100GB","maxUsedSpace":"100GB"}'

configure_docker_daemon() {
    local configure_gpu="${1:-false}" original candidate data_root total
    local reserved=0 free=0

    [[ -n "${work:-}" ]] || make_workdir
    original="$work/daemon.original.json"
    candidate="$work/daemon.json"
    if [[ -e "$docker_daemon" || -L "$docker_daemon" ]]; then
        as_root cat -- "$docker_daemon" > "$original"
    else
        printf '{}\n' > "$original"
    fi
    cp -- "$original" "$candidate"
    if [[ "$configure_gpu" == true ]]; then
        as_root nvidia-ctk runtime configure --runtime=docker --set-as-default --config="$candidate"
    fi
    if jq -e '
        .builder.gc as $gc | $gc.policy == null and
        ((($gc.defaultReservedSpace // "") == "" and ($gc.defaultKeepStorage // "") == "") or
         ($gc.defaultMinFreeSpace // "") == "")
    ' "$candidate" > /dev/null; then
        data_root="$(jq -r '."data-root" // "/var/lib/docker"' "$candidate")/buildkit"
        [[ "$data_root" == /* ]] || fail 'Docker data-root must be an absolute path.'
        while ! as_root test -e "$data_root"; do
            [[ "$data_root" != / ]] || fail 'Cannot access the Docker build cache filesystem.'
            data_root="$(dirname -- "$data_root")"
        done
        total="$(as_root df -B1 --output=size -- "$data_root" | awk 'NR == 2 {print $1}')"
        [[ "$total" =~ ^[0-9]+$ ]] || fail 'Cannot determine the Docker build cache filesystem size.'
        reserved="$(((total / 10 / 1073741824 + 1) * 1000000000))"
        free="$(((total / 5 / 1073741824 + 1) * 1000000000))"
    fi
    jq -e --argjson rule "$docker_gc_rule" --argjson reserved "$reserved" --argjson free "$free" '
        def bytes:
            if . == null or . == "" then 0 else
                [capture("^(?<n>[+]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?) ?(?<u>[kmgtp](?:ib|b)?|b)?$"; "i")] as $parts |
                if ($parts | length) != 1 then error("Invalid Docker GC size.") else
                    ($parts[0].n | tonumber) * pow(1024;
                        {"":0,"b":0,"k":1,"m":2,"g":3,"t":4,"p":5}[($parts[0].u // "" | ascii_downcase | .[0:1])])
                end
            end;
        if type != "object" or (.builder != null and (.builder | type) != "object") or
            (.builder.gc != null and (.builder.gc | type) != "object") then
            error("Docker daemon, builder and GC configuration must be objects.")
        else . end |
        .builder.gc.enabled = true |
        if .builder.gc.policy != null then
            if (.builder.gc.policy | type) != "array" then error("Docker GC policy must be an array.") else
                .builder.gc.policy |= if index($rule) == null then . + [$rule] else . end
            end
        else
            ($rule.maxUsedSpace | bytes) as $limit |
            (.builder.gc.defaultMaxUsedSpace | bytes) as $maximum |
            (if $maximum > 0 and $maximum <= $limit then $maximum else $limit end) as $cap |
            (if (.builder.gc.defaultReservedSpace // "") != "" then "defaultReservedSpace"
             elif (.builder.gc.defaultKeepStorage // "") != "" then "defaultKeepStorage"
             else "defaultReservedSpace" end) as $key |
            if $maximum == 0 or $maximum > $limit then .builder.gc.defaultMaxUsedSpace = $rule.maxUsedSpace else . end |
            if (.builder.gc[$key] // "") == "" then .builder.gc[$key] = ([$reserved, $cap] | min | tostring)
            elif (.builder.gc[$key] | bytes) > $cap then .builder.gc[$key] = ($cap | tostring) else . end |
            if (.builder.gc.defaultMinFreeSpace // "") == "" then .builder.gc.defaultMinFreeSpace = ($free | tostring) else . end
        end
    ' "$candidate" > "$work/daemon.configured.json"
    candidate="$work/daemon.configured.json"

    if jq -e --slurp '.[0] == .[1]' "$original" "$candidate" > /dev/null; then
        print_message info 'Docker build cache GC already configured.\n'
        return
    fi
    as_root dockerd --validate --config-file="$candidate"
    system_replace_file "$candidate" "$docker_daemon"
    print_message success 'Docker build cache GC configured: maximum used space at most 100GB.\n'
    print_message info 'Restart Docker to apply the daemon configuration.\n'
}

show_docker_gc_status() {
    local state

    if [[ ! -e "$docker_daemon" && ! -L "$docker_daemon" ]]; then
        state=not-configured
    elif [[ ! -r "$docker_daemon" ]] || ! command -v jq > /dev/null; then
        state="unknown: requires jq and a readable $docker_daemon"
    elif state="$(jq -er --argjson rule "$docker_gc_rule" '
        .builder.gc as $gc |
        if $gc.enabled != true then "not-configured"
        elif $gc.policy != null then
            if ($gc.policy | index($rule)) != null then "enabled; 100GB total-limit rule (file settings)"
            else "enabled; custom policies (file settings)" end
        else "enabled; maximum \($gc.defaultMaxUsedSpace // "Docker default") (file settings)" end
    ' "$docker_daemon" 2> /dev/null)"; then
        :
    else
        state="unknown: invalid $docker_daemon"
    fi
    print_message info '%-28s %s\n' 'Docker build cache GC' "$state"
}
