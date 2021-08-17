MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard *.vim)
TESTS := $(TESTS:.vim=)

.PHONY: test $(TESTS)

test: $(TESTS)

$(TESTS):
	@$(MYVIM) -u $@.vim

test-spaces: file\ with\ errors.log

file\ with\ errors.log: file\ with\ errors.tex input\ with\ spaces.tex
	@latexmk -file-line-error -interaction=nonstopmode -recorder -pdf \
	    file\ with\ errors.tex >/dev/null 2>&1 || true
	@mv "$@"{,.bak}
	@latexmk -C >/dev/null 2>&1
	@mv "$@"{.bak,}
