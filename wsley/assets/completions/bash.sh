#!/usr/bin/env bash

_wsley() {
    local candidate
    COMPREPLY=()

    while IFS= read -r candidate; do
        COMPREPLY+=("$candidate")
    done < <("${COMP_WORDS[0]}" __complete "${COMP_WORDS[@]:1:COMP_CWORD}" 2> /dev/null)
}

complete -F _wsley wsley
