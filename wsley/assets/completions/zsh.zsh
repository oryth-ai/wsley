# Load with eval "$(wsley completion zsh)" in .zshrc.

_wsley() {
    local -a candidates

    candidates=("${(@f)$("${words[1]}" __complete "${(@)words[2,CURRENT]}" 2> /dev/null)}")
    (( ${#candidates} )) && compadd -- "${candidates[@]}"
}

if (( ! $+functions[compdef] )); then
    autoload -Uz compinit
    compinit
fi
compdef _wsley wsley
