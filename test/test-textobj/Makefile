MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard *.vim)
TESTS := $(TESTS:.vim=)

.PHONY: test $(TESTS)

test: $(filter-out test-symbols,$(TESTS))

$(TESTS):
	@$(MYVIM) -u $@.vim
