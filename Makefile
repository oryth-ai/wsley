SHELL := /bin/bash
SHELL_FILES := $(shell find wsley scripts -type f -name '*.sh' | sort)
SHFMT_FLAGS := -i 4 -ci -sr

.DEFAULT_GOAL := help
.PHONY: help setup format check check-all

help: ## Show development commands
	@awk 'BEGIN { FS = ":.*## "; print "Commands:" } /^[a-z][a-z-]*:.*## / { printf "  make %-20s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

setup: ## Install development tools and Git hooks
	sudo apt update && sudo apt install python3 python3-tomlkit python3-yaml shfmt shellcheck zsh
	uv tool install --upgrade pre-commit
	uv tool install --upgrade ruff
	"$$(uv tool dir --bin)/pre-commit" install

format: ## Format Bash and Python sources
	@shfmt -w $(SHFMT_FLAGS) $(SHELL_FILES)
	@ruff check --isolated --line-length 100 --select I --fix wsley scripts
	@ruff format --isolated --line-length 100 --extend-exclude '*.md' wsley scripts

check: ## Check files changed in Git's index and worktree, including untracked files
	@bash scripts/check.sh

check-all: ## Check all project sources and validate the module list
	@bash scripts/check.sh --all
