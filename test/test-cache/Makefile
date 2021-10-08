MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

TESTS := $($(wildcard test-*.vim):.vim=)
TESTS_KPSEWHICH := test-kpsewhich-local-a test-kpsewhich-local-b
TESTS_ALL := $(TESTS) $(TESTS_KPSEWHICH)

.PHONY: test $(TESTS_ALL)

test: $(TESTS_ALL) test-cleanup

$(TESTS):
	@$(MYVIM) -u $@.vim

$(TESTS_KPSEWHICH):
	@cd $@ && $(MYVIM) -u test.vim

test-cleanup: $(TESTS_ALL)
	@rm kpsewhich.json
	@rm capture.json
