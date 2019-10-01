VIM ?= nvim --headless

MAKE := 1
export MAKE

TARGETS := glossaries glossaries-extra

test: $(TARGETS)

$(TARGETS): %: %.aux
	@nvim --headless -u $@.vim
	@latexmk -C $@.tex &>/dev/null

%.aux: %.tex
	@latexmk $< &>/dev/null

.PHONY: test $(TARGETS)
