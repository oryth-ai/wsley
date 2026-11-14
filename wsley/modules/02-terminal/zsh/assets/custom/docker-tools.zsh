docker-update-images() {
    emulate -L zsh

    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        if (($# != 1)); then
            print -u2 "docker-update-images: Help does not accept arguments."
            return 2
        fi
        cat << 'HELP'
Usage: docker-update-images [options]

Check local image tags against their registries and pull available updates.

Options:
  -h, --help    Show this help message and exit.

Notes:
  Each local repository:tag is checked once; untagged images are skipped.
  Docker reuses cached layers for tags that are already current.
  Uses the current Docker context, credentials and default platform.
  Containers keep using their current images until recreated.
  Pull failures do not stop other tags; any failure produces a nonzero exit.

Examples:
  docker-update-images
HELP
        return 0
    fi
    if (($#)); then
        print -u2 "docker-update-images: Arguments are not supported. Run docker-update-images --help."
        return 2
    fi
    if ! command -v docker > /dev/null 2>&1; then
        print -u2 "docker-update-images: Docker CLI is required."
        return 127
    fi

    local inventory image result
    local -i successes=0 failures=0
    local -a images

    inventory="$(command docker image ls --format '{{.Repository}}:{{.Tag}}')" || {
        result=$?
        print -u2 "docker-update-images: Could not list local images."
        return "$result"
    }
    for image in "${(@f)inventory}"; do
        [[ -z "$image" || "$image" == '<none>:'* || "$image" == *':<none>' ]] && continue
        images+=("$image")
    done
    images=("${(@u)images}")
    if ((${#images} == 0)); then
        print "docker-update-images: No tagged images found."
        return 0
    fi

    for image in "${images[@]}"; do
        print -r -- "docker-update-images: Checking $image"
        if command docker image pull -- "$image"; then
            ((successes += 1))
        else
            result=$?
            if ((result == 130 || result == 143)); then
                return "$result"
            fi
            print -ru2 -- "docker-update-images: Failed to pull $image (exit $result)."
            ((failures += 1))
        fi
    done

    print -r -- "docker-update-images: ${#images} tag(s) checked, $successes successful, $failures failed."
    ((failures == 0))
}
