MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

BACKENDS := bibtex bibparse vim

.PHONY: all $(BACKENDS) jobname

all: $(BACKENDS) jobname

$(BACKENDS):
	@BACKEND=$@ $(MYVIM) -u test_backend.vim

jobname:
	@$(MYVIM) -u test_jobname.vim
