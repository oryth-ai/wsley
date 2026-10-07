_process_tools_run_as_root() {
    if ((EUID == 0)); then
        command "$@"
    else
        command sudo -- "$@"
    fi
}

show-process-info() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        print "Usage: show-process-info <PID>"
        print "Description: Display a process summary and /proc/<PID> entries with elevated permissions."
        return 0
    fi

    if (($# != 1)); then
        print -u2 "Usage: show-process-info <PID>"
        return 1
    fi

    local pid="$1"
    if [[ "$pid" != <-> ]] || ((${#pid} > 10 || 10#$pid < 1 || 10#$pid > 2147483647)); then
        print -u2 "show-process-info: PID must be an integer from 1 to 2147483647."
        return 1
    fi
    pid="$((10#$pid))"

    if [[ ! -d /proc ]]; then
        print -u2 "show-process-info: The /proc filesystem is unavailable."
        return 1
    fi

    local process_directory="/proc/$pid"

    if ! command -v ps > /dev/null 2>&1; then
        print -u2 "show-process-info: ps is required; install procps."
        return 127
    fi

    local inspection_result
    _process_tools_run_as_root ps -p "$pid" -o pid,ppid,user,stat,etime,args || {
        inspection_result=$?
        print -u2 "show-process-info: Process $pid could not be inspected."
        return "$inspection_result"
    }

    print
    _process_tools_run_as_root ls -al -- "$process_directory"
}

show-port-info() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        print "Usage: show-port-info <port>"
        print "Description: Display local TCP/UDP sockets and their processes with elevated permissions."
        return 0
    fi

    if (($# != 1)); then
        print -u2 "Usage: show-port-info <port>"
        return 1
    fi

    local port="$1"
    if [[ "$port" != <-> ]] || ((${#port} > 5 || 10#$port < 1 || 10#$port > 65535)); then
        print -u2 "show-port-info: Port must be an integer from 1 to 65535."
        return 1
    fi
    port="$((10#$port))"

    if ! command -v ss > /dev/null 2>&1; then
        print -u2 "show-port-info: ss is required; install iproute2."
        return 127
    fi

    local socket_info
    socket_info="$(_process_tools_run_as_root ss -tunap "sport = :$port")" || return
    if [[ "$socket_info" != *$'\n'* ]]; then
        print "No TCP or UDP sockets use local port $port."
        return 0
    fi
    print -r -- "$socket_info"

    local socket_line
    for socket_line in "${(@f)socket_info}"; do
        if [[ "$socket_line" == (tcp|udp)[[:space:]]* && "$socket_line" != *'users:('* ]]; then
            print -u2 "Some sockets have no visible process details."
            break
        fi
    done
}
