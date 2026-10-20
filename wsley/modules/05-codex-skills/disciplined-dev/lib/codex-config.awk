BEGIN {
    assignment = "developer_instructions = \"" instruction "\""
    key = "^[ \t]*(developer_instructions|\"developer_instructions\"|'developer_instructions')[ \t]*="
    if (mode == "replace") {
        print assignment
    }
}

function scan(line, position, character, delimiter) {
    for (position = 1; position <= length(line); position++) {
        character = substr(line, position, 1)
        if (quote != "") {
            if (substr(quote, 1, 1) == "\"" && character == "\\") {
                position++
            } else if (substr(line, position, length(quote)) == quote) {
                delimiter = substr(quote, 1, 1)
                position += length(quote) - 1
                if (length(quote) == 3) {
                    while (substr(line, position + 1, 1) == delimiter) {
                        position++
                    }
                }
                quote = ""
            }
        } else if (character == "#") {
            break
        } else if (character == "\"" || character == "'") {
            quote = character
            if (substr(line, position, 3) == character character character) {
                quote = character character character
                position += 2
            }
        } else if (character == "[" || character == "{") {
            depth++
        } else if (character == "]" || character == "}") {
            depth--
            if (depth < 0) invalid = 1
        }
    }
    if (length(quote) == 1) invalid = 1
}

{
    if (quote == "" && depth == 0) {
        if ($0 ~ /^[ \t]*\[/) in_table = 1
        if (!in_table && match($0, key)) {
            if (found++) {
                invalid = 1
                exit
            }
            value = substr($0, RLENGTH + 1)
            sub(/^[ \t]*/, "", value)
            if (value !~ /^["']/) {
                invalid = 1
                exit
            }
            dropping = 1
            current = ($0 == assignment)
        }
    }

    scan($0)
    if (mode == "replace" && !dropping) print
    if (quote == "" && depth == 0) dropping = 0
}

END {
    if (invalid || quote != "" || depth != 0) {
        print "Cannot update Codex configuration: invalid TOML or developer_instructions is not a string." > "/dev/stderr"
        exit 2
    }
    if (mode == "check") exit !(found && current)
}
