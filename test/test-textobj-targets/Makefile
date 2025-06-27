MYVIM ?= nvim --clean --headless

INMAKE := 1
export INMAKE

.PHONY: test clean

test: | targets.vim
	@$(MYVIM) -u test.vim
	@diff test.ok test1.out
	@diff test.ok test2.out
	@rm test1.out test2.out

targets.vim:
	@git clone https://github.com/wellle/targets.vim.git
