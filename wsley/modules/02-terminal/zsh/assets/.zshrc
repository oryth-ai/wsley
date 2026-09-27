## >>> locale >>>
export LANG=C.UTF-8
export LANGUAGE=C.UTF-8
export LC_ALL=C.UTF-8
## <<< locale <<<

## >>> zsh >>>
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME="wsley-passion"
plugins=(
    zsh-autosuggestions
    zsh-syntax-highlighting
    git
    z
    sudo
)
DISABLE_AUTO_UPDATE="true" # Disable automatic updates
source "$ZSH/oh-my-zsh.sh"
## <<< zsh <<<

## >>> setting >>>
setopt no_nomatch
## <<< setting <<<
