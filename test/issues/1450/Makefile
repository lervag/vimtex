.PHONY: test clean

vim ?= nvim

test: tested.tex
	@git diff --no-index {correct,tested}.tex > test.diff \
	  && rm test.diff \
	  && echo 'SUCCESS' \
	  || (echo 'FAILED' && cat test.diff && exit 1)

tested.tex: clean
	@$(vim) -N -u NONE --noplugin -S minivimrc

clean:
	@rm -f tested.tex test.diff
