MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard test_*_reference.tex)
TESTS := $(TESTS:_reference.tex=)

.PHONY: test $(TESTS)

test: $(TESTS)

$(TESTS):
	@rm -f $@_output.tex
	@FILEIN=$@_input.tex FILEOUT=$@_output.tex $(MYVIM) -u test.vim
	@diff $@_output.tex $@_reference.tex
	@rm -f $@_output.tex

test_ampersands-off: export FLAGS=1
test_environments-ignored: export FLAGS=2
test_close-indented: export FLAGS=3
