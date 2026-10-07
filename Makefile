SHELL := /bin/bash
WSLEY := bash wsley/cli.sh
SHELL_FILES := $(shell find wsley -type f -name '*.sh' | sort)
ZSH_FILES := $(shell find wsley -type f \( -name '.zshrc' -o -name '*.zsh' -o -name '*.zsh-theme' \) | sort)
AWK_FILES := $(shell find wsley -type f -name '*.awk' | sort)
SHFMT_FLAGS := -i 4 -ci -sr

.DEFAULT_GOAL := help
.PHONY: help setup format check

help: ## Show development commands
	@awk 'BEGIN { FS = ":.*## "; print "Commands:" } /^[a-z][a-z-]*:.*## / { printf "  make %-20s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

setup: ## Install development tools and Git hooks
	sudo apt update && sudo apt install shfmt shellcheck zsh
	uv tool install --upgrade 'pre-commit>=4.6.2'
	"$$(uv tool dir --bin)/pre-commit" install

format: ## Format Bash scripts
	@shfmt -w $(SHFMT_FLAGS) $(SHELL_FILES)

check: ## Run static checks without installing software
	@shfmt -d $(SHFMT_FLAGS) $(SHELL_FILES)

	@for file in $(SHELL_FILES); do bash -n "$$file" || exit; done
	@shellcheck -x $(SHELL_FILES)
	@for file in $(ZSH_FILES); do zsh -n "$$file" || exit; done
	@for file in $(AWK_FILES); do awk -v mode=replace -f "$$file" /dev/null || exit; done

	@$(WSLEY) list > /dev/null
