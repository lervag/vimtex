INMAKE := 1
export INMAKE

TESTS := $(wildcard test*.lua)

.PHONY: default $(TESTS)

default: $(TESTS)

$(TESTS):
	@nvim --clean --headless -u $@
