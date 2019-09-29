.PHONY:

vim ?= nvim --headless

bibspeed:
	@MAKE=1                  $(vim) -u bibspeed.vim
	@MAKE=2 BACKEND=bibparse $(vim) -u bibspeed.vim
	@MAKE=3 BACKEND=vim      $(vim) -u bibspeed.vim
