MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard *.vim)
TESTS := $(TESTS:.vim=)

.PHONY: test $(TESTS)

test: $(TESTS)

$(TESTS):
	@latexmk $@.tex >/dev/null 2>&1
	@$(MYVIM) -u $@.vim
	@latexmk -C $@.tex >/dev/null 2>&1
