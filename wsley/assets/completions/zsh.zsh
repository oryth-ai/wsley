#compdef wsley

local -a candidates

candidates=("${(@f)$("${words[1]}" __complete "${(@)words[2,CURRENT]}" 2> /dev/null)}")
(( ${#candidates} )) && compadd -- "${candidates[@]}"
