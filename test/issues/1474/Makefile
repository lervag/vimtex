.PHONY: test

test: minimal.aux
	@nvim --headless -u minimal.vim

minimal.aux:
	@latexmk minimal.tex &>/dev/null
