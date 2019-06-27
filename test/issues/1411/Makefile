test:
	@rm -f out.tex
	@$(MAKE) out.tex
	diff out.tex expected.tex

out.tex:
	@nvim -u minivimrc
