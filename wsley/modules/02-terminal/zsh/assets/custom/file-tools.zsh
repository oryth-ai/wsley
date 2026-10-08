show-size() {
    local -i tree_depth=0 min_bytes=-1
    local tree_mode=true depth="" ignore_pattern="" min_size="" parsed_size="" min_size_set=false
    local -a paths=()

    while (($# > 0)); do
        case "$1" in
            -h | --help)
                print "Usage: show-size [-L depth] [-I pattern] [-s size|--min-size size] [path ...]"
                print "Description: Display path sizes as a tree; default to entries in the current directory."
                print "Options: -L depth Expand the tree to this depth; default: 1."
                print "     -I pattern Show matching directories without expanding them."
                print "     -s, --min-size size Show only files and directories whose disk usage exceeds size."
                print "        Use bytes or binary units K, M, G, T, P, E (optional B); e.g. 100M or 1.5G."
                return 0
                ;;
            -L)
                if (($# < 2)); then
                    print -u2 "show-size: -L requires a depth"
                    return 1
                fi
                depth="$2"
                tree_mode=true
                shift 2
                ;;
            -L*)
                depth="${1#-L}"
                tree_mode=true
                shift
                ;;
            -I)
                if (($# < 2)); then
                    print -u2 "show-size: -I requires a glob pattern"
                    return 1
                fi
                ignore_pattern="$2"
                shift 2
                ;;
            -I*)
                ignore_pattern="${1#-I}"
                shift
                ;;
            -s | --min-size)
                if (($# < 2)); then
                    print -u2 "show-size: $1 requires a size"
                    return 1
                fi
                min_size="$2"
                min_size_set=true
                shift 2
                ;;
            -s* | --min-size=*)
                min_size="${1#-s}"
                [[ "$1" == --min-size=* ]] && min_size="${1#--min-size=}"
                min_size_set=true
                shift
                ;;
            --)
                shift
                paths+=("$@")
                break
                ;;
            -*)
                print -u2 "show-size: Unknown option: $1"
                return 1
                ;;
            *)
                paths+=("$1")
                shift
                ;;
        esac
    done

    if [[ "$min_size_set" == true ]]; then
        if [[ "$min_size" =~ '^[0-9]+([.][0-9]+)?([KMGTPE]B?|B)?$' ]]; then
            parsed_size="${min_size%B}"
            if [[ "$parsed_size" == <-> ]]; then
                while [[ "$parsed_size" == 0?* ]]; do
                    parsed_size="${parsed_size#0}"
                done
            else
                parsed_size="$(awk -v size="$parsed_size" 'BEGIN {
                    unit = index("KMGTPE", substr(size, length(size)))
                    if (unit) size = substr(size, 1, length(size) - 1)
                    point = index(size, ".")
                    precision = point ? length(size) - point : 0
                    sub(/\./, "", size)
                    for (power = 0; power < unit; power++) {
                        converted = ""
                        carry = 0
                        for (digit = length(size); digit > 0; digit--) {
                            product = substr(size, digit, 1) * 1024 + carry
                            converted = (product % 10) converted
                            carry = int(product / 10)
                        }
                        size = (carry ? carry : "") converted
                    }
                    size = length(size) > precision ? substr(size, 1, length(size) - precision) : "0"
                    sub(/^0+/, "", size)
                    print length(size) ? size : "0"
                }')" || parsed_size=""
            fi
        fi
        if [[ "$parsed_size" != <-> ]] ||
            ((${#parsed_size} > 19)) ||
            [[ ${#parsed_size} == 19 && "$parsed_size" > 9223372036854775807 ]]; then
            print -u2 "show-size: size must be non-negative bytes or a binary size such as 100M or 1.5G (maximum: 9223372036854775807 bytes)"
            return 1
        fi
        min_bytes="$parsed_size"
    fi

    if [[ "$tree_mode" == true && -n "$depth" ]]; then
        if [[ "$depth" != <-> ]] || (($depth < 1)); then
            print -u2 "show-size: -L depth must be a positive integer"
            return 1
        fi
        tree_depth="$((depth - 1))"
    fi

    ((${#paths})) || paths=(*(DN))
    local target
    local result=0
    for target in "${paths[@]}"; do
        if [[ ! -e "$target" && ! -L "$target" ]]; then
            print -u2 "show-size: Path does not exist: $target"
            result=1
            continue
        fi
        if ((min_bytes >= 0)); then
            _show_size_tree_exceeds_size "$target" "$min_bytes" || continue
        fi
        _show_size_tree_node "$target" 0 "" true "$tree_depth" "$ignore_pattern" "$min_bytes"
    done
    return "$result"
}

_show_size_tree_size() {
    local size
    local -a size_options=(-sh)
    [[ "${2:-}" == bytes ]] && size_options=(-s -B1)
    size="$(du "${size_options[@]}" -- "$1" 2> /dev/null || :)"
    if [[ "$size" == *$'\t'* ]]; then
        size="${size%%$'\t'*}"
    else
        size="${size%% *}"
    fi
    [[ -n "$size" ]] || size="?"
    print -r -- "$size"
}

_show_size_tree_exceeds_size() {
    local bytes="$(_show_size_tree_size "$1" bytes)"
    [[ "$bytes" == <-> ]] && ((bytes > $2))
}

_show_size_tree_node() {
    local node_path="$1"
    local -i level="$2" max_depth="$5"
    local prefix="$3" is_last="$4"
    local ignore_pattern="${6:-}"
    local -i min_bytes="${7:--1}"
    local size="$(_show_size_tree_size "$node_path")"
    local name="${node_path:t}"
    local child_prefix="$prefix"

    if ((level == 0)); then
        print -r -- "$node_path $size"
    else
        local branch="├──"
        [[ "$is_last" == true ]] && branch="└──"
        print -r -- "$prefix$branch $name $size"
        [[ "$is_last" == true ]] && child_prefix+="    " || child_prefix+="│   "
    fi

    ((level >= max_depth)) && return 0
    [[ -d "$node_path" && ! -L "$node_path" ]] || return 0
    [[ -n "$ignore_pattern" && "$name" == ${~ignore_pattern} ]] && return 0

    local -a children=("$node_path"/*(N) "$node_path"/.[^.]*(N) "$node_path"/..?*(N))
    children=("${(@o)children}")
    if ((min_bytes >= 0)); then
        local -a matching_children=()
        local candidate
        for candidate in "${children[@]}"; do
            _show_size_tree_exceeds_size "$candidate" "$min_bytes" && matching_children+=("$candidate")
        done
        children=("${matching_children[@]}")
    fi
    local -i index=1 total="${#children[@]}"
    local child child_is_last
    for child in "${children[@]}"; do
        child_is_last=false
        ((index == total)) && child_is_last=true
        _show_size_tree_node "$child" "$((level + 1))" "$child_prefix" \
            "$child_is_last" "$max_depth" "$ignore_pattern" "$min_bytes"
        ((index++))
    done
}

cleanup-dirs() {
    local root="." include_generated=false verbose=false root_set=false

    while (($# > 0)); do
        case "$1" in
            -h | --help)
                print "Usage: cleanup-dirs [directory] [-g|--include-generated] [-v|--verbose]"
                print "Description: Remove common caches and empty directories; default: current directory."
                print "Options: -g, --include-generated Also remove .venv, node_modules, and dist directories."
                print "     -v, --verbose Print removed files and directories."
                return 0
                ;;
            -g | --include-generated)
                include_generated=true
                ;;
            -v | --verbose)
                verbose=true
                ;;
            --)
                shift
                if (($# > 1)); then
                    print -u2 "Usage: cleanup-dirs [directory] [-g|--include-generated] [-v|--verbose]"
                    return 1
                fi
                if (($# == 1)); then
                    root="$1"
                    root_set=true
                fi
                break
                ;;
            -*)
                print -u2 "cleanup-dirs: Unknown option: $1"
                return 1
                ;;
            *)
                if [[ "$root_set" == true ]]; then
                    print -u2 "cleanup-dirs: Only one directory is allowed."
                    return 1
                fi
                root="$1"
                root_set=true
                ;;
        esac
        shift
    done

    if [[ ! -d "$root" ]]; then
        print -u2 "cleanup-dirs: Directory does not exist: $root"
        return 1
    fi

    local -a remove_command=(rm -rf)
    [[ "$verbose" == true ]] && remove_command+=(-v)

    if [[ "$include_generated" == true ]]; then
        find "$root" \
            -type d -name .git -prune -o \
            -type d \( \
            -name .venv -o \
            -name node_modules -o \
            -name dist \
            \) -prune -exec "${remove_command[@]}" -- {} +
    fi

    find "$root" \
        -type d -name .git -prune -o \
        -type d \( \
        -name __pycache__ -o \
        -name .pytest_cache -o \
        -name .mypy_cache -o \
        -name .pytype -o \
        -name .ruff_cache -o \
        -name .hypothesis -o \
        -name .tox -o \
        -name .nox -o \
        -name .pyre -o \
        -name .pylint.d -o \
        -name .uv-cache -o \
        -name .astro -o \
        -name .svelte-kit -o \
        -name .docusaurus -o \
        -name .swc -o \
        -name .nx -o \
        -name .sass-cache -o \
        -name .parcel-cache -o \
        -name .turbo -o \
        -name .vite -o \
        -name .vitest -o \
        -name .nyc_output -o \
        -name coverage -o \
        -name htmlcov -o \
        -name test-results -o \
        -name playwright-report -o \
        -name blob-report -o \
        -name allure-results -o \
        -name allure-report \
        \) -prune -exec "${remove_command[@]}" -- {} +

    find "$root" \
        -type d -name .git -prune -o \
        -type d \( \
        -path '*/node_modules/.cache' -o \
        -path '*/node_modules/.astro' -o \
        -path '*/node_modules/.vite' -o \
        -path '*/.next/cache' -o \
        -path '*/.nuxt/cache' -o \
        -path '*/.angular/cache' -o \
        -path '*/.vercel/cache' -o \
        -path '*/cypress/screenshots' -o \
        -path '*/cypress/videos' -o \
        -path '*/cypress/downloads' \
        \) -prune -exec "${remove_command[@]}" -- {} +

    find "$root" \
        -type d -name .git -prune -o \
        -type f \( \
        -name '*.py[co]' -o \
        -name '.coverage' -o \
        -name '.coverage.*' -o \
        -name coverage.xml -o \
        -name junit.xml -o \
        -name test-results.xml -o \
        -name test-results.json -o \
        -name lcov.info -o \
        -name '*.tsbuildinfo' -o \
        -name .eslintcache -o \
        -name .stylelintcache \
        \) -exec "${remove_command[@]}" -- {} +

    find "$root" -depth -mindepth 1 \
        -type d \
        -not -path '*/.git' \
        -not -path '*/.git/*' \
        -empty -delete
}
