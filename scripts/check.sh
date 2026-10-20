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
        printf 'Usage: bash scripts/check.sh [--all]\n' >&2
        exit 2
        ;;
esac

changes="$(mktemp)"
trap 'rm -f -- "$changes"' EXIT
if [[ "$all" == false ]]; then
    git diff --name-only --no-renames -z > "$changes"
    git diff --cached --name-only --no-renames -z >> "$changes"
    git ls-files -z --others --exclude-standard >> "$changes"
    if grep -zFxq -e Makefile -e .pre-commit-config.yaml \
        -e scripts/check.sh -e wsley/lib/components.sh -e wsley/lib/modules.sh "$changes"; then
        all=true
    fi
fi
if [[ "$all" == true ]]; then
    git ls-files -z --cached --others --exclude-standard > "$changes"
fi

sort -zu -o "$changes" "$changes"

# shellcheck source=wsley/lib/components.sh
source wsley/lib/components.sh

checked=false
check_cli="$all"
bash_files=()
python_files=()
declare -A module_directories=()
while IFS= read -r -d '' file; do
    if [[ "$file" =~ ^(wsley/modules/[^/]+/[^/]+)/ ]]; then
        module_directories["${BASH_REMATCH[1]}"]=1
        check_cli=true
    fi
    [[ -f "$file" ]] || continue
    [[ "$file" != wsley/cli.sh ]] || check_cli=true
    case "$file" in
        wsley/*.sh | scripts/*.sh)
            bash -n "$file"
            bash_files+=("$file")
            continue
            ;;
        wsley/*.zsh | wsley/*.zsh-theme | wsley/.zshrc | wsley/*/.zshrc)
            zsh -n "$file"
            ;;
        wsley/*.awk) awk -f "$file" /dev/null ;;
        *.py)
            python_files+=("$file")
            continue
            ;;
        *.json) /usr/bin/python3 -B -c 'import json, sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$file" ;;
        *.yaml | *.yml) /usr/bin/python3 -B -c 'import sys, yaml; list(yaml.safe_load_all(open(sys.argv[1], encoding="utf-8")))' "$file" ;;
        wsley/modules/*/*/module.info)
            validate_module_info "$file"
            check_cli=true
            ;;
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
if ((${#python_files[@]})); then
    ruff check --isolated --line-length 100 --extend-select I "${python_files[@]}"
    ruff format --isolated --line-length 100 --check "${python_files[@]}"
    printf 'Checked %s\n' "${python_files[@]}"
    checked=true
fi
for file in wsley/modules/*/*/check.sh; do
    [[ -f "$file" ]] || continue
    [[ "$all" == true || -n "${module_directories[${file%/check.sh}]:-}" ]] || continue
    bash "$file"
    printf 'Checked module sources: %s\n' "${file%/check.sh}"
    checked=true
done
if [[ "$all" == true ]]; then
    pre-commit validate-config .pre-commit-config.yaml
fi
if [[ "$check_cli" == true ]]; then
    bash wsley/cli.sh list > /dev/null
    printf 'Checked module list\n'
    checked=true
fi
if [[ "$checked" == false ]]; then
    printf 'No changed project files to check.\n'
fi
