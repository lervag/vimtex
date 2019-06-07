.PHONY: test

test: test-vim test-nvim

test-nvim:
	@rm -f output
	@nvim -u minivimrc
	@grep "This line should be printed" output >/dev/null

test-vim:
	@rm -f output
	@vim --not-a-term -u minivimrc >/dev/null
	@grep "This line should be printed" output >/dev/null
