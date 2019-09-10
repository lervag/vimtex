.PHONY: test

test: minimal.aux
	@nvim --headless -u minivimrc

minimal.aux:
	@latexmk minimal.tex &>/dev/null
