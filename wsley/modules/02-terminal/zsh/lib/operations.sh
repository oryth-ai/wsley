#!/usr/bin/env bash

# shellcheck source=wsley/lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../lib/common.sh"

zsh_settings="$HOME/.config/wsley/zsh.sh"
if [[ -r "$zsh_settings" ]]; then
    # shellcheck disable=SC1090
    source "$zsh_settings"
fi
terminal_root="${ZSH:-${wsley_zsh_root:-$HOME/.oh-my-zsh}}"
custom="${ZSH_CUSTOM:-${wsley_zsh_custom:-$terminal_root/custom}}"
assets="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../assets" && pwd)"

install_zsh() {
    local mode="${1:-install}" config_file target

    [[ "$terminal_root" == /* && "$custom" == /* ]] || fail 'ZSH and ZSH_CUSTOM must be absolute paths.'
    require_user
    install_user_environment
    apt_install "${module_packages[@]}"

    if [[ ! -d "$terminal_root/.git" ]]; then
        git clone "$(component_ids "$module_components" git Shell)" "$terminal_root"
    else
        ZSH="$terminal_root" zsh "$terminal_root/tools/upgrade.sh" -v minimal
    fi

    local plugin repository
    mkdir -p "$custom/plugins"
    while IFS= read -r repository; do
        plugin="${repository##*/}"
        if [[ ! -d "$custom/plugins/$plugin/.git" ]]; then
            git clone "$repository" "$custom/plugins/$plugin"
        else
            git -C "$custom/plugins/$plugin" pull --ff-only
        fi
    done < <(component_ids "$module_components" git Plugins)

    if [[ "$mode" == upgrade ]]; then
        printf 'Zsh and plugins updated. User configuration and login shell preserved.\n'
        return
    fi

    mkdir -p "$custom/plugins" "$custom/themes"
    for config_file in "$assets"/custom/*.zsh; do
        target="$custom/${config_file##*/}"
        backup_file "$target"
        rm -f -- "$target"
        cp -p "$config_file" "$target"
    done

    backup_file "$custom/themes/wsley-passion.zsh-theme"
    mkdir -p "${ZDOTDIR:-$HOME}"
    backup_file "${ZDOTDIR:-$HOME}/.zshrc"
    rm -f -- "$custom/themes/wsley-passion.zsh-theme" "${ZDOTDIR:-$HOME}/.zshrc"
    cp -p "$assets/themes/wsley-passion.zsh-theme" "$custom/themes/wsley-passion.zsh-theme"
    {
        printf 'export ZSH=%q\n' "$terminal_root"
        printf 'export ZSH_CUSTOM=%q\n\n' "$custom"
        cat "$assets/.zshrc"
    } > "${ZDOTDIR:-$HOME}/.zshrc"
    register_shell_integration

    backup_file "$zsh_settings"
    {
        printf 'wsley_zsh_root=%q\n' "$terminal_root"
        printf 'wsley_zsh_custom=%q\n' "$custom"
    } > "$zsh_settings"

    as_root usermod -s /bin/zsh "$(id -un)"
    printf 'Zsh configuration installed. Open a new Zsh session.\n'
}

show_zsh_status() {
    local repository directory
    local -a directories

    package_status "${module_packages[@]}"

    directories=("$terminal_root")
    while IFS= read -r repository; do
        directories+=("$custom/plugins/${repository##*/}")
    done < <(component_ids "$module_components" git Plugins)

    for directory in "${directories[@]}"; do
        if [[ -d "$directory/.git" ]]; then
            printf '%-28s %s\n' "${directory##*/}" "$(git -C "$directory" rev-parse --short HEAD)"
        else
            printf '%-28s not-installed\n' "${directory##*/}"
        fi
    done

    configuration_status "${ZDOTDIR:-$HOME}/.zshrc"
}
