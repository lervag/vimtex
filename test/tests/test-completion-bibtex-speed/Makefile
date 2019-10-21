.PHONY: test

MYVIM ?= nvim --headless

test:
	@INMAKE=1                  $(MYVIM) -u bibspeed.vim
	@INMAKE=1 BACKEND=bibparse $(MYVIM) -u bibspeed.vim
	@INMAKE=1 BACKEND=vim      $(MYVIM) -u bibspeed.vim
