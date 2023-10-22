MYVIM ?= nvim --clean --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard test*.vim)
TESTS := $(filter-out test_backend,$(TESTS:.vim=))
BACKENDS := bibtex vim lua

.PHONY: test $(TESTS) $(BACKENDS) test-cleanup

test: $(TESTS) $(BACKENDS) test-cleanup

$(TESTS):
	@$(MYVIM) -u $@.vim

$(BACKENDS):
	@BACKEND=$@ $(MYVIM) -u test_backend.vim

test-cleanup: $(TESTS_ALL)
	@rm -f nvim_servernames.log
