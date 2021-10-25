MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard test*.vim)
TESTS := $(TESTS:.vim=)

.PHONY: default $(TESTS)

default: $(TESTS)

$(TESTS):
	@$(MYVIM) -u $@.vim
