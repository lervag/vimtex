.PHONY: test

MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

test:
	@echo -n $(MYVIM) -u test.vim " timed to ... "
	@bash -c 'time -p $(MYVIM) -u test.vim &>/dev/null' 2>&1 | grep real
