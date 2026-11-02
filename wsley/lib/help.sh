#!/usr/bin/env bash

show_wsley_help() {
    local action="${1:-}" synopsis description

    case "$action" in
        '')
            cat << 'HELP'
Usage: wsley <command> [options] [arguments]

Manage an Ubuntu development environment.

Commands:
  list          List modules and groups, or show module details.
  install       Install missing module components.
  upgrade       Update installed module components.
  status        Show module status.
  self-upgrade  Update the Wsley checkout and shell environment.
  help          Show help for Wsley or a command.

Options:
  -h, --help    Show this help message and exit.

Examples:
  wsley list
  wsley list zsh
  wsley install terminal --yes
  wsley help upgrade

Run 'wsley <command> --help' for command-specific help.
HELP
            return
            ;;
        list)
            synopsis='[options] [<module|group>...]'
            description='List modules and groups, or show details for selected modules.'
            ;;
        install)
            synopsis='[options] <module|group>...'
            description='Install missing components for the selected modules.'
            ;;
        upgrade)
            synopsis='[options] <module|group>...'
            description='Update installed components for the selected modules.'
            ;;
        status)
            synopsis='[options] <module|group>...'
            description='Show the status of the selected modules.'
            ;;
        self-upgrade)
            synopsis='[options]'
            description='Update the Wsley checkout from its configured upstream branch.'
            ;;
        help)
            cat << 'HELP'
Usage: wsley help [<command>]

Show help for Wsley or a command.

Arguments:
  <command>     Command to describe; omit it for general help.

Options:
  -h, --help    Show this help message and exit.
HELP
            return
            ;;
        *)
            printf 'Unknown command: %s. Run wsley --help.\n' "$action" >&2
            return 2
            ;;
    esac

    printf 'Usage: wsley %s %s\n\n%s\n' "$action" "$synopsis" "$description"
    if [[ "$action" != self-upgrade ]]; then
        cat << 'HELP'

Arguments:
  <module|group>  Case-sensitive module or group names; names can be mixed.
HELP
    fi
    printf '\nOptions:\n  -h, --help    Show this help message and exit.\n'
    if [[ "$action" == install || "$action" == upgrade || "$action" == self-upgrade ]]; then
        printf '  -y, --yes     Skip action confirmation.\n'
    fi

    if [[ "$action" == self-upgrade ]]; then
        cat << 'HELP'

Notes:
  Refreshes the Wsley PATH environment after updating the checkout.
  Overwriting local changes or diverged history requires separate confirmation.
  Force overwrite defaults to no and is never implied by --yes.
HELP
    else
        printf '\nNotes:\n  Run wsley list to see available modules and groups.\n'
        if [[ "$action" != list ]]; then
            printf '  Each selected module is processed once, in argument order.\n'
        fi
        if [[ "$action" == install || "$action" == upgrade ]]; then
            printf '  --yes does not skip APT mirror or Docker proxy questions.\n'
        fi
    fi
}

show_module_help() {
    local script="$1" action module_directory module
    action="${script##*/}"
    action="${action%.sh}"
    if [[ "$action" == self-upgrade ]]; then
        show_wsley_help "$action"
        return
    fi
    module_directory="$(dirname -- "$script")"
    module="${module_directory##*/}"

    printf 'Usage: bash %s [options]\n\n' "$script"
    module_section "$module_directory/module.info" "${action^}" | fmt -w 80
    printf '\nOptions:\n  -h, --help    Show this help message and exit.\n'
    if [[ "$action" != status ]]; then
        printf '  -y, --yes     Skip action confirmation.\n'
        printf '\nNotes:\n  --yes does not skip APT mirror or Docker proxy questions.\n'
    fi
    printf '\nEquivalent command:\n  wsley %s %s\n' "$action" "$module"
}
