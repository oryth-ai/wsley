#!/usr/bin/env sh

export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"

case ":${PATH:-}:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME${PATH:+:$PATH}" ;;
esac

case ":${PATH:-}:" in
    *":$PNPM_HOME/bin:"*) ;;
    *) export PATH="$PNPM_HOME/bin${PATH:+:$PATH}" ;;
esac
