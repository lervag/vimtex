MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard test*.vim)
TESTS := $(filter-out test_backend,$(TESTS:.vim=))
BACKENDS := bibtex bibparse vim

.PHONY: test $(TESTS) $(BACKENDS)

test: $(TESTS) $(BACKENDS)

$(TESTS):
	@$(MYVIM) -u $@.vim

$(BACKENDS):
	@BACKEND=$@ $(MYVIM) -u test_backend.vim
