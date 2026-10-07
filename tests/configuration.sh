#!/usr/bin/env bash

set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_directory="$(mktemp -d)"
trap 'rm -rf -- "$fixture_directory"' EXIT
export HOME="$fixture_directory/home"
export XDG_STATE_HOME="$fixture_directory/state"
export ZDOTDIR="$HOME/zsh dotfiles"
export ZSH="$HOME/oh my zsh"
export ZSH_CUSTOM="$ZSH/my custom"
mkdir -p "$HOME" "$ZDOTDIR"

# shellcheck source=wsley/modules/02-terminal/zsh/lib/operations.sh
source "$root/wsley/modules/02-terminal/zsh/lib/operations.sh"

assert_backup() {
    local target="$1" expected="$2" key
    key="$(printf '%s' "$(realpath -ms -- "$target")" | sha256sum)"
    [[ "$(cat "$XDG_STATE_HOME/wsley/backups/${key%% *}/original")" == "$expected" ]]
}

printf 'original zshrc\n' > "$ZDOTDIR/.zshrc"
configure_zsh install
[[ "$(cat "$ZDOTDIR/.zshrc")" == 'original zshrc' ]]
require_user() { :; }
apt_upgrade() { :; }
upgrade_zsh_repository() { :; }
module_packages=()
module_components="$root/wsley/modules/02-terminal/zsh/components.tsv"
upgrade_zsh
assert_backup "$ZDOTDIR/.zshrc" 'original zshrc'
[[ "$(head -n 1 "$ZDOTDIR/.zshrc")" == "$(printf 'export ZSH=%q' "$ZSH")" ]]
for asset in "$assets"/custom/*.zsh "$assets"/themes/*.zsh-theme; do
    target="$custom/${asset##*/}"
    [[ "$asset" != *.zsh-theme ]] || target="$custom/themes/${asset##*/}"
    cmp "$asset" "$target"
    printf 'stale\n' > "$target"
done
upgrade_zsh
for asset in "$assets"/custom/*.zsh "$assets"/themes/*.zsh-theme; do
    target="$custom/${asset##*/}"
    [[ "$asset" != *.zsh-theme ]] || target="$custom/themes/${asset##*/}"
    cmp "$asset" "$target"
done
assert_backup "$ZDOTDIR/.zshrc" 'original zshrc'

printf 'stale path\n' > "$HOME/.config/wsley/environment/path.sh"
# The first backup records that path.sh was created by Wsley.
install_user_environment
cmp "$root/wsley/assets/environment/path.sh" "$HOME/.config/wsley/environment/path.sh"
# shellcheck source=wsley/lib/node.sh
source "$root/wsley/lib/node.sh"
export PNPM_HOME="$HOME/custom pnpm"
configure_node_environment
export PNPM_HOME="$HOME/another pnpm"
configure_node_environment
unset PNPM_HOME
# shellcheck disable=SC1091
source "$HOME/.config/wsley/environment/node.sh"
[[ "$PNPM_HOME" == "$HOME/another pnpm" ]]
install_user_environment
[[ "$(rg -Fc '.config/wsley/environment/init.sh' "$ZDOTDIR/.zshenv")" == 1 ]]

load_module_context() {
    module_directory="$1"
    module_packages=()
}
preflight_module() { :; }
for module in tmux vim; do
    file="$HOME/.tmux.conf"
    line='set -g mouse on'
    if [[ "$module" == vim ]]; then
        file="$HOME/.vimrc"
        line='set number'
    fi
    printf 'user configuration' > "$file"
    # shellcheck disable=SC1090
    source "$root/wsley/modules/02-terminal/$module/upgrade.sh" --yes
    # shellcheck disable=SC1090
    source "$root/wsley/modules/02-terminal/$module/upgrade.sh" --yes
    [[ "$(head -n 1 "$file")" == 'user configuration' ]]
    [[ "$(rg -Fxc "$line" "$file")" == 1 ]]
    assert_backup "$file" 'user configuration'
    rm "$file"
    # shellcheck disable=SC1090
    source "$root/wsley/modules/02-terminal/$module/upgrade.sh" --yes
    [[ ! -e "$file" ]]
done
# shellcheck source=wsley/lib/self-upgrade.sh
source "$root/wsley/lib/self-upgrade.sh"
git init -q --initial-branch=main "$fixture_directory/upstream"
git -C "$fixture_directory/upstream" config user.name 'Wsley Test'
git -C "$fixture_directory/upstream" config user.email 'test@example.invalid'
printf 'first\n' > "$fixture_directory/upstream/version"
git -C "$fixture_directory/upstream" add version
git -C "$fixture_directory/upstream" commit -qm first
git clone -q "$fixture_directory/upstream" "$fixture_directory/checkout"
printf 'second\n' > "$fixture_directory/upstream/version"
git -C "$fixture_directory/upstream" commit -qam second
printf 'stale path\n' > "$HOME/.config/wsley/environment/path.sh"
self_upgrade_wsley "$fixture_directory/checkout" --yes
[[ "$(cat "$fixture_directory/checkout/version")" == second ]]
cmp "$root/wsley/assets/environment/path.sh" "$HOME/.config/wsley/environment/path.sh"
printf 'Configuration regression checks passed.\n'
