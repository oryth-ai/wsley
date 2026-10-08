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

install_zsh_repository() {
    local directory="$1" repository="$2"

    if [[ -e "$directory/.git" ]]; then
        print_message info 'Skipped %s: already installed.\n' "${directory##*/}"
        return
    fi
    git clone "$repository" "$directory"
}

upgrade_zsh_repository() {
    local directory="$1"

    if [[ ! -e "$directory/.git" ]]; then
        print_message info 'Skipped %s: not installed.\n' "${directory##*/}"
        return
    fi
    git -C "$directory" pull --ff-only
}

install_zsh() {
    local zsh_state plugin repository

    [[ "$terminal_root" == /* && "$custom" == /* ]] || fail 'ZSH and ZSH_CUSTOM must be absolute paths.'
    require_user
    zsh_state="$(package_state zsh)"
    apt_install "${module_packages[@]}"
    install_user_environment

    install_zsh_repository "$terminal_root" "$(component_ids "$module_components" git Shell)"

    while IFS= read -r repository; do
        plugin="${repository##*/}"
        install_zsh_repository "$custom/plugins/$plugin" "$repository"
    done < <(component_ids "$module_components" git Plugins)

    configure_zsh install

    if [[ "$zsh_state" == missing ]]; then
        as_root usermod -s /bin/zsh "$(id -un)"
    fi
    print_message success 'Zsh setup complete. Open a new Zsh session.\n'
}

configure_zsh() {
    local action="$1" config_file target

    mkdir -p "$custom/plugins" "$custom/themes" "${ZDOTDIR:-$HOME}"
    for config_file in "$assets"/custom/*.zsh "$assets"/themes/*.zsh-theme; do
        if [[ "$config_file" == *.zsh-theme ]]; then
            target="$custom/themes/${config_file##*/}"
        else
            target="$custom/${config_file##*/}"
        fi
        if [[ "$action" == upgrade || (! -e "$target" && ! -L "$target") ]]; then
            backup_file "$target"
            cp -p "$config_file" "$target"
        fi
    done

    target="${ZDOTDIR:-$HOME}/.zshrc"
    backup_file "$target"
    {
        printf 'export ZSH=%q\n' "$terminal_root"
        printf 'export ZSH_CUSTOM=%q\n\n' "$custom"
        cat "$assets/.zshrc"
    } > "$target"

    backup_file "$zsh_settings"
    {
        printf 'wsley_zsh_root=%q\n' "$terminal_root"
        printf 'wsley_zsh_custom=%q\n' "$custom"
    } > "$zsh_settings"
}

upgrade_zsh() {
    local repository

    [[ "$terminal_root" == /* && "$custom" == /* ]] || fail 'ZSH and ZSH_CUSTOM must be absolute paths.'
    require_user
    apt_upgrade "${module_packages[@]}"
    upgrade_zsh_repository "$terminal_root"
    while IFS= read -r repository; do
        upgrade_zsh_repository "$custom/plugins/${repository##*/}"
    done < <(component_ids "$module_components" git Plugins)
    if [[ -e "$terminal_root/.git" || -e "${ZDOTDIR:-$HOME}/.zshrc" || -L "${ZDOTDIR:-$HOME}/.zshrc" ]]; then
        install_user_environment
        configure_zsh upgrade
    else
        print_message info 'Skipped Zsh configuration: not installed.\n'
    fi
}

show_zsh_status() {
    local repository directory revision failed=0
    local -a directories

    package_status "${module_packages[@]}"

    directories=("$terminal_root")
    while IFS= read -r repository; do
        directories+=("$custom/plugins/${repository##*/}")
    done < <(component_ids "$module_components" git Plugins)

    for directory in "${directories[@]}"; do
        if [[ -e "$directory/.git" ]]; then
            if revision="$(git -C "$directory" rev-parse --short HEAD)"; then
                print_message success '%-28s %s\n' "${directory##*/}" "$revision"
            else
                print_message error '%-28s query-failed\n' "${directory##*/}" >&2
                failed=1
            fi
        else
            print_message warning '%-28s not-installed\n' "${directory##*/}"
        fi
    done

    configuration_status "${ZDOTDIR:-$HOME}/.zshrc"
    return "$failed"
}
