.PHONY: test

MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

test:
	@chronic timeout 1 $(MYVIM) -u test.vim
