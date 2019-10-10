TESTS := $(wildcard test-*)

.PHONY: test $(TESTS)

MYVIM ?= nvim --headless

test: $(TESTS)

$(TESTS):
	$(MAKE) -C $@
