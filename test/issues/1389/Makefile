.PHONY: test

test:
	@rm new.tex
	@$(MAKE) new.tex
	diff new.tex target.tex

new.tex:
	@nvim -u minivimrc
