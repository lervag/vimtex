MYVIM ?= nvim --clean --headless
VIM   ?= vim -e -s

INMAKE := 1
export INMAKE

UNIT_TESTS := test.vim
INTG_TESTS := test-integration.vim

.PHONY: test vim integration $(UNIT_TESTS) $(INTG_TESTS)

test: $(UNIT_TESTS)

vim:
	@for t in $(UNIT_TESTS); do $(VIM) -u $$t; done

integration: $(INTG_TESTS)

$(UNIT_TESTS) $(INTG_TESTS):
	@$(MYVIM) -u $@
