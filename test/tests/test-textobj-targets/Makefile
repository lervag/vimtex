MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

.PHONY: test clean

test: test.out | targets.vim
	git diff --no-index test1.ok test1.out > test1.diff \
	  && rm test1.diff \
	  || echo 'Failed (see test1.diff)'

test.out: clean
	@chronic $(MYVIM) -u test.vim

clean:
	@rm -f *.{out,diff}

targets.vim:
	@git clone https://github.com/wellle/targets.vim.git
