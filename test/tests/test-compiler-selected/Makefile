.PHONY: test

MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

test: output1 output2
	@diff output1.tex reference1.tex
	@diff output2.tex reference2.tex
	@rm -f output*.tex

output%:
	@$(MYVIM) -u test.vim
