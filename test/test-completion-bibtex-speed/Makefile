.PHONY: test

MYVIM ?= nvim --clean --headless

test:
	@INMAKE=1 BACKEND=bibtex       $(MYVIM) -u bibspeed.vim
	@INMAKE=1 BACKEND=vim          $(MYVIM) -u bibspeed.vim
	@INMAKE=1 BACKEND=lua          $(MYVIM) -u bibspeed.vim
	@#INMAKE=1 BACKEND=bibparse     $(MYVIM) -u bibspeed.vim
	@#INMAKE=1 BACKEND=bibtexparser $(MYVIM) -u bibspeed.vim
	@rm -f nvim_servernames.log
