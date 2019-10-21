MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

TESTS := $(wildcard test_*_reference.tex)
TESTS := $(TESTS:.tex=)

.PHONY: test
.PRECIOUS: test_%_output.tex

test: $(TESTS)

test_%_reference: test_%_output.tex
	@diff $@.tex $<
	@rm -f $<

test_%_output.tex: test_%_input.tex test.vim Makefile
	@FILEIN=$< FILEOUT=$@ $(MYVIM) -u test.vim

test_ampersands-off_output.tex: export FLAGS=1
test_environments-ignored_output.tex: export FLAGS=2
test_close-indented_output.tex: export FLAGS=3
