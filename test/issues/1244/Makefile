PHONY: test

test: indented.tex
	diff indented.tex correct.tex

indented.tex: minivimrc
	nvim -u minivimrc
