MYVIM ?= nvim --headless

MAKE := 1
export MAKE

test: main.aux
	@$(MYVIM) -u minimal.vim
	@latexmk -C &>/dev/null

main.aux:
	@latexmk main.tex &>/dev/null

.PHONY: test
