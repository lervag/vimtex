MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

.PHONY: test clean

test: test1.out
	@diff test1.ok test1.out
	@rm test1.out

test1.out: | targets.vim
	@chronic $(MYVIM) -u test.vim

targets.vim:
	@git clone https://github.com/wellle/targets.vim.git
