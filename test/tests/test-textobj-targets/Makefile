MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

.PHONY: test clean

test: test1.out | targets.vim
	@diff test1.ok test1.out
	@rm test1.out

test1.out: clean
	@chronic $(MYVIM) -u test.vim

clean:
	@rm -f *.{out,diff}

targets.vim:
	@git clone https://github.com/wellle/targets.vim.git
