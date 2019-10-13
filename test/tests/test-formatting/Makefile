MYVIM ?= nvim --headless

MAKE := 1
export MAKE

TESTS := $(wildcard *.ref)
TESTS := $(TESTS:.ref=)

.PHONY: test $(TESTS)

test: $(TESTS)

$(TESTS):
	@FILE=$@ $(MYVIM) -u test.vim
	@diff $@.out $@.ref
