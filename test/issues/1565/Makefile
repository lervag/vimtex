.PHONY: test

MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

test:
	@$(MYVIM) -u test.vim
	@grep -A 18 'FUNCTION.*uniq' prof.log
