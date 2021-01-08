MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard *.ref)
TESTS := $(TESTS:.ref=)

.PHONY: test $(TESTS)

test: $(TESTS)
	@rm -f test-*.out

$(TESTS):
	@FILE=$@ $(MYVIM) -u test.vim
	@diff $@.out $@.ref
