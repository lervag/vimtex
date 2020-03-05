MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard test*.vim)
TESTS := $(TESTS:.vim=)

.PHONY: test $(TESTS)

test: $(TESTS)

$(TESTS):
	@$(MYVIM) -u $@.vim

test-large: | syntax/asy.vim

syntax/asy.vim:
	@echo -n "-- Fetching asy.vim ... "
	@mkdir -p syntax
	@wget \
	  https://raw.githubusercontent.com/vectorgraphics/asymptote/master/base/asy.vim \
	  -O syntax/asy.vim >/dev/null 2>&1
	@echo "done"
