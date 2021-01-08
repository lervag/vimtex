.PHONY: test

MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

test: file\ with\ errors.log
	@$(MYVIM) -u test.vim
	@$(MYVIM) -u test-logparsers.vim
	@latexmk -C >/dev/null 2>&1
	@rm -f input.aux\ 

file\ with\ errors.log:
	@latexmk -file-line-error -interaction=nonstopmode -recorder -pdf \
	    file\ with\ errors.tex >/dev/null 2>&1 || true
