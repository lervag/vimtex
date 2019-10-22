MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

.PHONY: test

test:
	@chronic $(MYVIM) -u test.vim
	@rm -f minimal.*
