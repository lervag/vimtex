.PHONY: glossaries glossaries-extra

glossaries: glossaries.aux
	@nvim --headless -u glossaries.vim
	@#latexmk -C

glossaries-extra: glossaries-extra.aux
	@nvim --headless -u glossaries.vim
	@#latexmk -C

%.aux: %.tex
	@latexmk $<
