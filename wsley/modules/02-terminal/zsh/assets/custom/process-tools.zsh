show-process-info() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        print "Usage: show-process-info [PID]"
        print "Description: Display /proc/<PID> information; default: current shell."
        return 0
    fi

    local pid="${1:-$$}"
    local user_groups="$(groups)"
    local -a command_prefix=()
    [[ "$user_groups" == *root* || "$user_groups" == *sudo* ]] && command_prefix=(sudo)

    "${command_prefix[@]}" ls -al "/proc/$pid"
}

show-port-info() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        print "Usage: show-port-info [port]"
        print "Description: Display processes using a port; default: 22."
        return 0
    fi

    local port="${1:-22}"
    local user_groups="$(groups)"
    local -a command_prefix=()
    [[ "$user_groups" == *root* || "$user_groups" == *sudo* ]] && command_prefix=(sudo)

    "${command_prefix[@]}" lsof -i:"$port"
}
