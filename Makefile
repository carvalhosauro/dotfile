.PHONY: install stow unstow test test-debian test-fedora clean help

DOTFILE_DIR := $(shell pwd)

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Full bootstrap (packages + stow)
	./bootstrap.sh

stow: ## Link dotfiles only
	./stow-all.sh

unstow: ## Unlink all dotfiles
	@for pkg in zsh starship mise tmux nvim ghostty alacritty; do \
		if [ -d "$(DOTFILE_DIR)/$$pkg" ]; then \
			echo "unstowing $$pkg..."; \
			stow --dir="$(DOTFILE_DIR)" --target="$(HOME)" --delete $$pkg 2>/dev/null || true; \
		fi; \
	done
	@echo "done. all packages unlinked."

test-debian: ## Test bootstrap in Debian container
	docker build -t dotfile-test-debian -f tests/Dockerfile.debian .
	docker run --rm dotfile-test-debian

test-fedora: ## Test bootstrap in Fedora container
	docker build -t dotfile-test-fedora -f tests/Dockerfile.fedora .
	docker run --rm dotfile-test-fedora

test: test-debian test-fedora ## Run all tests

clean: unstow ## Unstow + remove backups
	rm -rf $(HOME)/.dotfile-backup-*
