export LANG=C.UTF-8
export LANGUAGE=C.UTF-8
export LC_ALL=C.UTF-8

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME="wsley-passion"
plugins=(
    zsh-autosuggestions
    zsh-syntax-highlighting
    git
    z
    sudo
)
DISABLE_AUTO_UPDATE="true"
source "$ZSH/oh-my-zsh.sh"

setopt no_nomatch
