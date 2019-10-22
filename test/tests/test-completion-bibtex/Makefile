MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

BACKENDS := bibtex bibparse vim

.PHONY: all $(BACKENDS)

all: $(BACKENDS)

$(BACKENDS):
	@BACKEND=$@ $(MYVIM) -u test.vim
