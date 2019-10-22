.PHONY: test

MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

test: main.aux
	@$(MYVIM) -u test.vim
	@latexmk -C >/dev/null 2>&1

main.aux:
	@latexmk main.tex >/dev/null 2>&1
