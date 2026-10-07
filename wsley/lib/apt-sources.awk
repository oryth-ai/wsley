BEGIN {
    if (format == "deb822") {
        RS = ""
        ORS = "\n\n"
    }
    official = "https?://(([a-zA-Z0-9-]+\\.)?archive|security|ports)\\.ubuntu\\.com/(ubuntu-ports|ubuntu)(/|[[:space:]]|$)"
    host = "https?://(([a-zA-Z0-9-]+\\.)?archive|security|ports)\\.ubuntu\\.com/"
}

function process_uri(line) {
    if (line ~ official) {
        found = 1
        if (mode == "replace") {
            gsub(host, "https://mirrors.aliyun.com/", line)
        }
    }
    return line
}

{
    if (format != "deb822") {
        line = $0
        if (line ~ /^[ \t]*deb(-src)?[ \t]+/) {
            comment = ""
            position = index(line, "#")
            if (position) {
                comment = substr(line, position)
                line = substr(line, 1, position - 1)
            }
            line = process_uri(line) comment
        }
        if (mode == "replace") {
            print line
        }
        next
    }

    count = split($0, lines, "\n")
    active = 1
    for (i = 1; i <= count; i++) {
        if (tolower(lines[i]) ~ /^enabled:[ \t]*no[ \t]*$/) {
            active = 0
        }
    }

    in_uris = 0
    for (i = 1; i <= count; i++) {
        if (lines[i] ~ /^[ \t]*#/) {
            continue
        }
        if (lines[i] ~ /^[^ \t]/) {
            in_uris = (tolower(lines[i]) ~ /^uris:/)
        }
        if (active && in_uris) {
            lines[i] = process_uri(lines[i])
        }
    }

    if (mode == "replace") {
        for (i = 1; i <= count; i++) {
            printf "%s\n", lines[i]
        }
        printf "\n"
    }
}

END {
    if (mode == "check") {
        exit !found
    }
}
