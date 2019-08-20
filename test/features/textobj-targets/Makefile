.PHONY: test fetch clean

vim ?= nvim
vimargs = -N -u NONE --noplugin -S

test: fetch test.out
	@git diff --no-index test1.{ok,out} > test1.diff \
	  && rm test1.diff \
	  && echo 'test1 OK' \
	  || echo 'test1 failed (see test1.diff)'

fetch: | targets.vim vim-gitgutter

targets.vim:
	git clone https://github.com/wellle/targets.vim.git

vim-gitgutter:
	git clone https://github.com/airblade/vim-gitgutter

test.out: clean
	@$(vim) $(vimargs) test.vim

clean:
	@rm -f *.{out,diff}
