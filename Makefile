SHELL := /bin/bash
SHELL_FILES := $(shell find wsley -type f -name '*.sh' | sort)
SHFMT_FLAGS := -i 4 -ci -sr

.DEFAULT_GOAL := help
.PHONY: help setup format check check-all

help: ## Show development commands
	@awk 'BEGIN { FS = ":.*## "; print "Commands:" } /^[a-z][a-z-]*:.*## / { printf "  make %-20s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

setup: ## Install development tools and Git hooks
	sudo apt update && sudo apt install shfmt shellcheck zsh
	uv tool install --upgrade 'pre-commit>=4.6.2'
	"$$(uv tool dir --bin)/pre-commit" install

format: ## Format Bash scripts
	@shfmt -w $(SHFMT_FLAGS) $(SHELL_FILES)

check: ## Check files changed in Git's index and worktree, including untracked files
	@bash wsley/check.sh

check-all: ## Check all project sources and validate the module list
	@bash wsley/check.sh --all
