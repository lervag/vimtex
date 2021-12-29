.PHONY: test

MYVIM ?= nvim --clean --headless

INMAKE := 1
export INMAKE

test:
	@$(MYVIM) -u test.vim 2>&1
