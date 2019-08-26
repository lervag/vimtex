.PHONY: test clean

vim ?= nvim --headless

test: clean before.out after.out
	@diff -q before.out after.out
	@$(MAKE) clean

%.out:
	@MAKE=1 $(vim) -u minivimrc 2>/dev/null

clean:
	@rm -f *.out
