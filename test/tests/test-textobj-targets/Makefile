MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

.PHONY: test fetch clean

test: fetch test.out
	@git diff --no-index test1.{ok,out} > test1.diff \
	  && rm test1.diff \
	  || echo 'Failed (see test1.diff)'

fetch: | targets.vim vim-gitgutter

targets.vim:
	@git clone https://github.com/wellle/targets.vim.git

vim-gitgutter:
	@git clone https://github.com/airblade/vim-gitgutter

test.out: clean
	@$(MYVIM) -u test.vim

clean:
	@rm -f *.{out,diff}
