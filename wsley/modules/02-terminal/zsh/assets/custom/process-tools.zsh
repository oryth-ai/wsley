_process_tools_run_as_root() {
    if ((EUID == 0)); then
        command "$@"
    else
        command sudo -- "$@"
    fi
}

show-process-info() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        if (($# != 1)); then
            print -u2 "show-process-info: Help does not accept arguments."
            return 2
        fi
        cat << 'HELP'
Usage: show-process-info [options] <pid>

Display a process summary and list its /proc entries with elevated permissions.

Arguments:
  <pid>         Process ID from 1 to 2147483647.

Options:
  -h, --help    Show this help message and exit.

Examples:
  show-process-info 1234
HELP
        return 0
    fi

    if (($# != 1)); then
        print -u2 "show-process-info: Expected one process ID. Run show-process-info --help."
        return 2
    fi

    local pid="$1"
    if [[ "$pid" != <-> ]] || ((${#pid} > 10 || 10#$pid < 1 || 10#$pid > 2147483647)); then
        print -u2 "show-process-info: PID must be an integer from 1 to 2147483647."
        return 2
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
        if (($# != 1)); then
            print -u2 "show-port-info: Help does not accept arguments."
            return 2
        fi
        cat << 'HELP'
Usage: show-port-info [options] <port>

Display local TCP/UDP sockets and their processes with elevated permissions.

Arguments:
  <port>        Local port from 1 to 65535.

Options:
  -h, --help    Show this help message and exit.

Examples:
  show-port-info 8080
HELP
        return 0
    fi

    if (($# != 1)); then
        print -u2 "show-port-info: Expected one port. Run show-port-info --help."
        return 2
    fi

    local port="$1"
    if [[ "$port" != <-> ]] || ((${#port} > 5 || 10#$port < 1 || 10#$port > 65535)); then
        print -u2 "show-port-info: Port must be an integer from 1 to 65535."
        return 2
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
