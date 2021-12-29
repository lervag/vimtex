.PHONY: test

MYVIM ?= nvim --clean --headless

test:
	@INMAKE=1                      $(MYVIM) -u bibspeed.vim
	@INMAKE=1 BACKEND=vim          $(MYVIM) -u bibspeed.vim
	@#INMAKE=1 BACKEND=bibparse     $(MYVIM) -u bibspeed.vim
	@#INMAKE=1 BACKEND=bibtexparser $(MYVIM) -u bibspeed.vim
	@rm -f nvim_servernames.log
