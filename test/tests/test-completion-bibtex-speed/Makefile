.PHONY: test

MYVIM ?= nvim --headless

test:
	@MAKE=1                  $(MYVIM) -u bibspeed.vim
	@MAKE=1 BACKEND=bibparse $(MYVIM) -u bibspeed.vim
	@MAKE=1 BACKEND=vim      $(MYVIM) -u bibspeed.vim
