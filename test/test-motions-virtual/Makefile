MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

.PHONY: test

test:
	@chronic $(MYVIM) -u test.vim
	@diff test.out test.ref; rm test.out
