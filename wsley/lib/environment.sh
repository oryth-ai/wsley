#!/usr/bin/env bash

install_environment() (
    local name="$1" source_file="$2" file line stage template
    local directory="$HOME/.config/wsley/environment"
    local zsh_directory="${ZDOTDIR:-$HOME}"

    [[ -r "$source_file" ]] || fail "Missing environment source: $source_file"

    mkdir -p "$directory" "$zsh_directory"
    stage="$(mktemp -d "$directory/.stage.XXXXXX")"
    trap 'rm -rf -- "$stage"' EXIT
    cp -- "$source_file" "$stage/$name.sh"

    cat > "$stage/init.sh" << 'ENV'
#!/usr/bin/env sh

for wsley_environment_file in "$HOME"/.config/wsley/environment/path.sh "$HOME"/.config/wsley/environment/node.sh; do
    [ -r "$wsley_environment_file" ] || continue
    . "$wsley_environment_file"
done
unset wsley_environment_file
ENV

    for file in "$stage"/*.sh; do
        template="${file##*/}"
        if ! cmp -s -- "$file" "$directory/$template"; then
            backup_file "$directory/$template"
            mv -- "$file" "$directory/$template"
        fi
    done

    # shellcheck disable=SC2016
    line='[ ! -r "$HOME/.config/wsley/environment/init.sh" ] || . "$HOME/.config/wsley/environment/init.sh"'
    for file in "$(bash_login_file)" "$HOME/.bashrc" "$zsh_directory/.zshenv"; do
        register_shell_configuration "$file" "Wsley environment" "$line"
    done
    register_shell_integration
)

install_user_environment() {
    install_environment path "$(dirname -- "${BASH_SOURCE[0]}")/../assets/environment/path.sh"
}

bash_login_file() {
    local file

    for file in "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"; do
        if [[ -f "$file" ]]; then
            printf '%s\n' "$file"
            return
        fi
    done
    printf '%s\n' "$HOME/.profile"
}

register_shell_integration() {
    local file line

    if [[ -r "$HOME/.config/wsley/shell/bash.sh" ]]; then
        # shellcheck disable=SC2016
        line='[ ! -r "$HOME/.config/wsley/shell/bash.sh" ] || . "$HOME/.config/wsley/shell/bash.sh"'
        for file in "$(bash_login_file)" "$HOME/.bashrc"; do
            register_shell_configuration "$file" "Wsley Bash integration" "$line"
        done
    fi
    if [[ -r "$HOME/.config/wsley/shell/zsh.zsh" ]]; then
        # shellcheck disable=SC2016
        line='[ ! -r "$HOME/.config/wsley/shell/zsh.zsh" ] || . "$HOME/.config/wsley/shell/zsh.zsh"'
        register_shell_configuration "${ZDOTDIR:-$HOME}/.zshrc" "Wsley Zsh integration" "$line"
    fi
}

register_shell_configuration() {
    local file="$1" description="$2" line="$3"

    if grep -Fxq "$line" "$file" 2> /dev/null; then
        return
    fi

    backup_file "$file"
    if [[ -s "$file" ]]; then
        if [[ -n "$(tail -c 1 -- "$file")" ]]; then
            printf '\n' >> "$file"
        fi
        [[ -z "$(tail -n 1 -- "$file")" ]] || printf '\n' >> "$file"
    fi
    printf '# %s\n%s\n' "$description" "$line" >> "$file"
}
