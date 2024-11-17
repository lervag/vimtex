INMAKE := 1
export INMAKE

TESTS_LUA := $(wildcard test*.lua)
TESTS_VIM := $(wildcard test*.vim)

.PHONY: test $(TESTS_LUA) $(TESTS_VIM)

default: $(TESTS_LUA) $(TESTS_VIM)

MYVIM ?= nvim --clean --headless

$(TESTS_VIM):
	@$(MYVIM) -u $@

$(TESTS_LUA):
	@nvim --clean --headless -u $@
