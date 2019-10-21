.PHONY: test

MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

test: | syntax/asy.vim
	@$(MYVIM) -u test.vim

syntax/asy.vim:
	@mkdir -p syntax
	@wget \
	  https://raw.githubusercontent.com/vectorgraphics/asymptote/master/base/asy.vim \
	  -O syntax/asy.vim
