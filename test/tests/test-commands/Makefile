MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard test*.vim)
TESTS := $(TESTS:.vim=)

.PHONY: test $(TESTS)

test: $(TESTS)

$(TESTS):
	@chronic $(MYVIM) -u $@.vim
