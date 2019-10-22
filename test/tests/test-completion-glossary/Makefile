.PHONY: test $(TARGETS)

MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

TARGETS := glossaries glossaries-extra

test: $(TARGETS)

glossaries: glossaries.aux
	@nvim --headless -u $@.vim
	@latexmk -C $@.tex >/dev/null 2>&1

glossaries-extra:
	@TEXFILE=$@-1.tex nvim --headless -u $@.vim
	@TEXFILE=$@-2.tex nvim --headless -u $@.vim

%.aux: %.tex
	@latexmk $< >/dev/null 2>&1
