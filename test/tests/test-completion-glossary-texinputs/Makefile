MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

.PHONY: test

test:
	@$(MYVIM) -u test.vim
	@rm -f kpsewhich.json
