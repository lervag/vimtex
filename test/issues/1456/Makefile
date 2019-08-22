.PHONY: test clean

vim ?= nvim --headless

test: clean reply
	@diff reference reply && echo "SUCCESS"

reply:
	@$(vim) -u minivimrc

clean:
	@rm -f reply
