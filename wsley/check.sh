#!/usr/bin/env bash

set -euo pipefail
export LC_ALL=C

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
git rev-parse --show-toplevel > /dev/null

all=false
case "$*" in
    '') ;;
    --all) all=true ;;
    *)
        printf 'Usage: bash wsley/check.sh [--all]\n' >&2
        exit 2
        ;;
esac

changes="$(mktemp)"
trap 'rm -f -- "$changes"' EXIT
if [[ "$all" == true ]]; then
    git ls-files -z --cached --others --exclude-standard -- wsley > "$changes"
else
    git diff --name-only --no-renames --diff-filter=ACMR -z -- wsley > "$changes"
    git diff --cached --name-only --no-renames --diff-filter=ACMR -z -- wsley >> "$changes"
    git ls-files -z --others --exclude-standard -- wsley >> "$changes"
fi

sort -zu -o "$changes" "$changes"

# shellcheck source=wsley/lib/components.sh
source wsley/lib/components.sh

checked=false
check_cli="$all"
bash_files=()
while IFS= read -r -d '' file; do
    [[ -f "$file" ]] || continue
    [[ "$file" != wsley/cli.sh ]] || check_cli=true
    case "$file" in
        wsley/*.sh)
            bash -n "$file"
            bash_files+=("$file")
            continue
            ;;
        wsley/*.zsh | wsley/*.zsh-theme | wsley/.zshrc | wsley/*/.zshrc)
            zsh -n "$file"
            ;;
        wsley/*.awk) awk -v mode=replace -f "$file" /dev/null ;;
        wsley/modules/*/*/module.info) validate_module_info "$file" ;;
        wsley/modules/*/*/components.tsv) validate_components "$file" ;;
        *) continue ;;
    esac
    printf 'Checked %s\n' "$file"
    checked=true
done < "$changes"

if ((${#bash_files[@]})); then
    shfmt -d -i 4 -ci -sr "${bash_files[@]}"
    shellcheck -x "${bash_files[@]}"
    printf 'Checked %s\n' "${bash_files[@]}"
    checked=true
fi
if [[ "$check_cli" == true ]]; then
    bash wsley/cli.sh list > /dev/null
    printf 'Checked module list\n'
fi
if [[ "$checked" == false ]]; then
    printf 'No changed project files to check.\n'
fi
