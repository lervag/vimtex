MYVIM ?= nvim --clean --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard test*.vim)

.PHONY: test $(TESTS)

test: $(TESTS)

$(TESTS):
	@$(MYVIM) -u $@
