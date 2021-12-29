MYVIM ?= nvim --clean --headless
MAKEFLAGS+=--no-print-directory

TESTS := $(wildcard test-*)

.PHONY: test $(TESTS)

test: $(TESTS)

$(TESTS):
	$(MAKE) -C $@
