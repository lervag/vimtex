MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

BACKENDS := bibtex bibparse vim

.PHONY: all $(BACKENDS) jobname globbed starred multicite

all: $(BACKENDS) jobname globbed starred multicite

$(BACKENDS):
	@BACKEND=$@ $(MYVIM) -u test_backend.vim

jobname:
	@$(MYVIM) -u test_jobname.vim

globbed:
	@$(MYVIM) -u test_globbed.vim

starred:
	@$(MYVIM) -u test_starred.vim

multicite:
	@$(MYVIM) -u test_multicite.vim

parser_bcf:
	@$(MYVIM) -u test_parser_bcf.vim

parser_blg:
	@$(MYVIM) -u test_parser_blg.vim
