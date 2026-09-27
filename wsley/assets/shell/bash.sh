#!/usr/bin/env bash

[ -n "${BASH_VERSION:-}" ] || return 0
case $- in
    *i*) ;;
    *) return 0 ;;
esac

# shellcheck disable=SC1091
source "${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions/wsley"
