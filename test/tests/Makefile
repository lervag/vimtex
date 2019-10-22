MYVIM ?= nvim --headless
MAKEFLAGS+=--no-print-directory

TESTS := $(wildcard test-*)

.PHONY: test $(TESTS)

test: $(TESTS)

$(TESTS):
	$(MAKE) -C $@

# Force serial processing
test-indentation: MAKEFLAGS := $(MAKEFLAGS) -j1
test-completion-bibtex: MAKEFLAGS := $(MAKEFLAGS) -j1
test-completion-bibtex-speed: MAKEFLAGS := $(MAKEFLAGS) -j1

# Ensure that some tests are run last
FILTERED := test-indentation-timing
test-indentation-timing: | $(filter-out $(FILTERED), $(TESTS))

FILTERED += test-completion-bibtex-speed
test-completion-bibtex-speed: | $(filter-out $(FILTERED), $(TESTS))

FILTERED += test-completion-bibtex
test-completion-bibtex: | $(filter-out $(FILTERED), $(TESTS))
