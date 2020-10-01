.PHONY: test

MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

test: output1 output2 output3
	@diff output1.tex reference1.tex
	@diff output2.tex reference2.tex
	@diff output3.tex reference3.tex
	@rm -f output*.tex

output%:
	@$(MYVIM) -u test.vim
