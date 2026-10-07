# Modified from the original by ChesterYue: https://github.com/ChesterYue/ohmyzsh-theme-passion

directory() {
    local color="%{$fg_bold[blue]%}"
    local directory="${PWD/#$HOME/~}"
    local color_reset="%{$reset_color%}"
    echo "${color}${directory}${color_reset}"
}

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}(%{$fg_bold[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[blue]%})"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[blue]%})"

update_git_status() {
    GIT_STATUS=$(_omz_git_prompt_info)
}

git_status() {
    echo "${GIT_STATUS}"
}

update_command_status() {
    local arrow=""
    local color_reset="%{$reset_color%}"
    local reset_font="%{$fg_no_bold[white]%}"
    COMMAND_RESULT=$1
    if [[ "$COMMAND_RESULT" == true ]]; then
        arrow="%{$fg_bold[red]%}❯%{$fg_bold[yellow]%}❯%{$fg_bold[green]%}❯"
    else
        arrow="%{$fg_bold[red]%}❯❯❯"
    fi
    COMMAND_STATUS="${arrow}${reset_font}${color_reset}"
}

update_command_status true

command_status() {
    echo "${COMMAND_STATUS}"
}

precmd() {
    local last_cmd_return_code=$?
    local last_cmd_result
    if ((last_cmd_return_code == 0)); then
        last_cmd_result=true
    else
        last_cmd_result=false
    fi

    update_git_status

    update_command_status "$last_cmd_result"
}

TMOUT=1
TRAPALRM() {
    if [[ -z "$WIDGET" || "$WIDGET" == accept-line ]]; then
        zle reset-prompt
    fi
}

setopt PROMPT_SUBST

PROMPT='$(directory) $(git_status)$(command_status) '
