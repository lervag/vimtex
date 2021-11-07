MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard *.vim)
TESTS := $(TESTS:.vim=)

.PHONY: test $(TESTS) test-cleanup

test: $(TESTS) test-cleanup

$(TESTS):
	@$(MYVIM) -u $@.vim

test-cleanup: $(TESTS)
	@rm -f nvim_servernames.log
