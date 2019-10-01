MYVIM ?= nvim --headless

TESTS := $(wildcard test-*)

test: $(TESTS)

$(TESTS):
	$(MAKE) -C $@

.PHONY: test $(TESTS)
