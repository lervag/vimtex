.PHONY: test

MYVIM ?= nvim --headless

MAKE := 1
export MAKE

test: main.aux
	@$(MYVIM) -u test.vim
	@latexmk -C &>/dev/null

main.aux:
	@latexmk main.tex &>/dev/null
