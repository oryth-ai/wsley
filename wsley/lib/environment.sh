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

    # Publish complete environment files.
    for file in "$stage"/*.sh; do
        template="${file##*/}"
        backup_file "$directory/$template"
        mv -f -- "$file" "$directory/$template"
    done

    # Expand HOME when the shell loads this configuration.
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

register_shell_configuration() (
    local file="$1" description="$2" line="$3" stage input=/dev/null

    stage="$(mktemp)"
    trap 'rm -f -- "$stage"' EXIT

    [[ ! -f "$file" ]] || input="$file"

    # Annotate existing entries in place and separate them from other settings.
    awk -v entry="$line" -v heading="# $description" '
        function write_entry() {
            if (previous != heading) {
                if (previous != "") print ""
                print heading
            }
            print entry
            separator = 1
            found = 1
        }
        $0 == entry {
            if (!found) write_entry()
            next
        }
        {
            if (separator && $0 != "") print ""
            separator = 0
            print
            previous = $0
        }
        END {
            if (!found) write_entry()
        }
    ' "$input" > "$stage"

    if cmp -s -- "$stage" "$file"; then
        return
    fi

    backup_file "$file"
    cat -- "$stage" > "$file"
)
