.PHONY: fetch

fetch: | targets.vim gitgutter

targets.vim:
	git clone https://github.com/wellle/targets.vim.git

gitgutter:
	git clone https://github.com/airblade/vim-gitgutter

clean:
	@rm -f *.{out,diff}

test: clean
	@vim -N -u NONE --noplugin -S test.vim # test with vim
	@# nvim -N -u NONE --noplugin -S test.vim # test with neovim
	@# @/usr/bin/vim -N -u NONE --noplugin -S test.vim # test old vim version

check: test
	@git diff --no-index test1.ok  test1.out  > test1.diff  && rm test1.diff  && echo "test1  OK" || echo "test1  failed, check test1.diff"
