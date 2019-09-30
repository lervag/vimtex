.PHONY: test

VIM ?= nvim --headless

test:
	@MAKE=1                  $(VIM) -u bibspeed.vim
	@MAKE=2 BACKEND=bibparse $(VIM) -u bibspeed.vim
	@MAKE=3 BACKEND=vim      $(VIM) -u bibspeed.vim
