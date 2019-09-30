.PHONY: glossaries glossaries-extra

default:

glossaries: glossaries.aux
	@nvim --headless -u glossaries.vim
	@#latexmk -C

glossaries-extra: glossaries-extra.aux
	@nvim --headless -u glossaries.vim
	@#latexmk -C

%.aux: %.tex
	@latexmk $<
