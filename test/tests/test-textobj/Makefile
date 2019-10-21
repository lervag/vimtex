MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard *.vim)
TESTS := $(TESTS:.vim=)

.PHONY: test $(TESTS)

test: $(TESTS)

$(TESTS):
	@$(MYVIM) -u $@.vim
