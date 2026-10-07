[[ -o interactive ]] || return 0

if (( ! ${fpath[(Ie)${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions]} )); then
    fpath=("${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions" $fpath)
fi

if (( ! $+functions[compdef] )); then
    autoload -Uz compinit
    compinit
fi

autoload -Uz _wsley
compdef _wsley wsley
