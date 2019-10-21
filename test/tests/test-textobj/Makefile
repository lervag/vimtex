MYVIM ?= nvim --headless

MAKE := 1
export MAKE

TESTS := $(wildcard *.vim)
TESTS := $(TESTS:.vim=)

.PHONY: test $(TESTS)

test: $(TESTS)

$(TESTS):
	@$(MYVIM) -u $@.vim
